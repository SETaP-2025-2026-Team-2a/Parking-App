import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'data/cubit.dart';
import 'search_data/search.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final MapController _mapController = MapController();
  final FlutterTts _tts = FlutterTts();
  final DataCubit _dataCubit = DataCubit();
  final SearchService _searchService = SearchService(
    baseUrl: 'http://localhost:8080',
  );

  LatLng _startLocation = const LatLng(51.5072, -0.1276);
  LatLng _selectedLocation = const LatLng(51.5072, -0.1276);
  String _selectedLabel = 'London';

  List<LatLng> _routePoints = const [];
  List<String> _directions = const [];
  List<_NavigationStep> _navigationSteps = const [];
  double _routeDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  int _nextVoiceStepIndex = 0;
  bool _arrivalAnnounced = false;
  int _currentStepPromptStage = 0;
  double? _lastDistanceToStep;

  bool _isSearching = false;
  bool _isRouting = false;
  bool _isLocating = false;
  bool _followUser = false;
  bool _speechEnabled = true;
  String? _errorMessage;
  StreamSubscription<Position>? _positionSubscription;

  // Distance filters for car park search
  double _minDistance = 0.0;
  double _maxDistance = 5.0;
  List<CarPark> _searchedCarParks = [];
  bool _isSearchingCarParks = false;

  @override
  void initState() {
    super.initState();
    _configureTts();
    _setUserLocation();
    _dataCubit.fetch();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tts.stop();
    _dataCubit.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
  }

  Future<void> _setSpeechEnabled(bool enabled) async {
    setState(() {
      _speechEnabled = enabled;
    });

    if (!enabled) {
      await _tts.stop();
    }
  }

  Future<void> _setUserLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are off. Enable location to use your current position.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permission denied. Using default location instead.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      if (!mounted) {
        return;
      }

      setState(() {
        _startLocation = userLocation;
        _selectedLocation = userLocation;
        _selectedLabel = 'Your location';
        _followUser = true;
        _errorMessage = null;
      });

      _startPositionTracking();
      _mapController.move(userLocation, 15);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not get your current location.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _startPositionTracking() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!mounted) {
            return;
          }

          final current = LatLng(position.latitude, position.longitude);
          setState(() {
            _startLocation = current;
          });

          if (_followUser) {
            _mapController.move(current, 16);
          }

          _checkNavigationVoice(current);
        });
  }

  Future<void> _speakNavigationIntro() async {
    if (!_speechEnabled || _directions.isEmpty) {
      return;
    }

    final preview = _directions.take(2).join('. ');
    final message =
        'Starting navigation to $_selectedLabel. Distance ${_formatDistance(_routeDistanceMeters)}. Estimated time ${_formatDuration(_routeDurationSeconds)}. $preview';

    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> _checkNavigationVoice(LatLng current) async {
    if (!_speechEnabled) {
      return;
    }

    if (_navigationSteps.isEmpty ||
        _nextVoiceStepIndex >= _navigationSteps.length) {
      if (_arrivalAnnounced) {
        return;
      }

      final distanceToDestination = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (distanceToDestination <= 40) {
        _arrivalAnnounced = true;
        await _tts.stop();
        await _tts.speak('You have arrived at your destination.');
      }
      return;
    }

    final step = _navigationSteps[_nextVoiceStepIndex];
    final distanceToStep = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      step.maneuverPoint.latitude,
      step.maneuverPoint.longitude,
    );
    final spokenInstruction = _instructionWithoutDistance(step.instruction);

    if (_currentStepPromptStage == 0 &&
        distanceToStep <= 350 &&
        distanceToStep > 60) {
      _currentStepPromptStage = 1;
      await _tts.stop();
      await _tts.speak(_buildApproachPrompt(distanceToStep, spokenInstruction));
    }

    if (distanceToStep <= 60) {
      _nextVoiceStepIndex++;
      _currentStepPromptStage = 0;
      _lastDistanceToStep = null;
      await _tts.stop();
      await _tts.speak(_buildImmediatePrompt(spokenInstruction));
      return;
    }

    if (_currentStepPromptStage == 1 &&
        _lastDistanceToStep != null &&
        distanceToStep > _lastDistanceToStep! + 30) {
      _nextVoiceStepIndex++;
      _currentStepPromptStage = 0;
      _lastDistanceToStep = null;
      return;
    }

    _lastDistanceToStep = distanceToStep;
  }

  String _instructionWithoutDistance(String instruction) {
    return instruction.replaceAll(RegExp(r'\s*\([^\)]*\)$'), '').trim();
  }

  String _buildApproachPrompt(double distanceMeters, String instruction) {
    if (distanceMeters >= 250) {
      return 'In ${_formatDistance(distanceMeters)}, $instruction.';
    }
    if (distanceMeters >= 120) {
      return 'In about ${distanceMeters.round()} meters, $instruction.';
    }
    return 'Coming up, $instruction.';
  }

  String _buildImmediatePrompt(String instruction) {
    return 'Now, $instruction.';
  }

  Future<void> _onSearchPressed() async {
    if (_isSearching || _isSearchingCarParks || _isRouting || _isLocating) {
      return;
    }
    await _searchLocation();
  }

  Future<void> _searchLocation() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a location to search.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '1',
      });

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'setap-parking-app/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Search failed with status ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) {
        setState(() {
          _errorMessage = 'No locations found for "$query".';
        });
        return;
      }

      final result = data.first as Map<String, dynamic>;
      final lat = double.parse(result['lat'] as String);
      final lon = double.parse(result['lon'] as String);
      final label = (result['display_name'] as String?) ?? query;
      final newLocation = LatLng(lat, lon);

      setState(() {
        _selectedLocation = newLocation;
        _selectedLabel = label;
      });

      // Search for car parks near the selected location
      await _searchCarParksNearby();

      final didLoadRoute = await _loadRoute(_startLocation, newLocation);
      if (didLoadRoute) {
        setState(() {
          _followUser = true;
        });
        _mapController.move(_startLocation, 16);
        await _speakNavigationIntro();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to search location right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _routeToCarParkByCoordinates(CarPark carPark) async {
    setState(() {
      _isRouting = true;
      _errorMessage = null;
    });

    try {
      final newLocation = LatLng(carPark.latitude, carPark.longitude);

      setState(() {
        _selectedLocation = newLocation;
        _selectedLabel = carPark.name;
      });

      final didLoadRoute = await _loadRoute(_startLocation, newLocation);
      if (didLoadRoute) {
        setState(() {
          _followUser = true;
        });
        _mapController.move(_startLocation, 16);
        await _speakNavigationIntro();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to route to this car park right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _routeToCarParkByName(String name) async {
    setState(() {
      _isRouting = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': name,
        'format': 'jsonv2',
        'limit': '1',
      });

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'setap-parking-app/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Search failed with status ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) {
        throw Exception('No location found for car park');
      }

      final result = data.first as Map<String, dynamic>;
      final lat = double.parse(result['lat'] as String);
      final lon = double.parse(result['lon'] as String);
      final newLocation = LatLng(lat, lon);

      setState(() {
        _selectedLocation = newLocation;
        _selectedLabel = name;
      });

      final didLoadRoute = await _loadRoute(_startLocation, newLocation);
      if (didLoadRoute) {
        setState(() {
          _followUser = true;
        });
        _mapController.move(_startLocation, 16);
        await _speakNavigationIntro();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to route to this car park right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  Future<void> _searchCarParksNearby() async {
    if (_isSearchingCarParks) {
      return;
    }

    setState(() {
      _isSearchingCarParks = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchInDistanceRange(
        query: '', // Empty query to get all car parks in range
        longitude: _selectedLocation.longitude,
        latitude: _selectedLocation.latitude,
        minDistanceKm: _minDistance,
        maxDistanceKm: _maxDistance,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searchedCarParks = results;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to search car parks: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCarParks = false;
        });
      }
    }
  }

  String _formatCarParkSubtitle(CarPark carPark) {
    return '${carPark.distance.toStringAsFixed(1)} km away';
  }

  Future<bool> _loadRoute(LatLng from, LatLng to) async {
    setState(() {
      _isRouting = true;
    });

    try {
      final path =
          '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
      final uri = Uri.https('router.project-osrm.org', path, {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Route request failed: ${response.statusCode}');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw Exception('No route available');
      }

      final Map<String, dynamic> route = routes.first as Map<String, dynamic>;
      final Map<String, dynamic> geometry =
          route['geometry'] as Map<String, dynamic>;
      final List<dynamic> coordinates =
          geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((dynamic item) {
        final pair = item as List<dynamic>;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();

      final List<String> parsedDirections = [];
      final List<_NavigationStep> parsedNavigationSteps = [];
      final List<dynamic> legs = route['legs'] as List<dynamic>;
      if (legs.isNotEmpty) {
        final Map<String, dynamic> firstLeg =
            legs.first as Map<String, dynamic>;
        final List<dynamic> steps = firstLeg['steps'] as List<dynamic>;
        for (final stepData in steps) {
          final step = stepData as Map<String, dynamic>;
          final instruction = _buildDirection(step);
          parsedDirections.add(instruction);

          final maneuver = (step['maneuver'] as Map<String, dynamic>?) ?? {};
          final location = maneuver['location'] as List<dynamic>?;
          if (location != null && location.length == 2) {
            parsedNavigationSteps.add(
              _NavigationStep(
                instruction: instruction,
                maneuverPoint: LatLng(
                  (location[1] as num).toDouble(),
                  (location[0] as num).toDouble(),
                ),
              ),
            );
          }
        }
      }

      setState(() {
        _routePoints = points;
        _directions = parsedDirections;
        _navigationSteps = parsedNavigationSteps;
        _routeDistanceMeters = (route['distance'] as num).toDouble();
        _routeDurationSeconds = (route['duration'] as num).toDouble();
        _nextVoiceStepIndex = 0;
        _arrivalAnnounced = false;
        _currentStepPromptStage = 0;
        _lastDistanceToStep = null;
      });
      return true;
    } catch (_) {
      setState(() {
        _routePoints = const [];
        _directions = const [];
        _navigationSteps = const [];
        _routeDistanceMeters = 0;
        _routeDurationSeconds = 0;
        _nextVoiceStepIndex = 0;
        _arrivalAnnounced = false;
        _currentStepPromptStage = 0;
        _lastDistanceToStep = null;
        _errorMessage = 'Could not generate directions for this destination.';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  String _buildDirection(Map<String, dynamic> step) {
    final maneuver = (step['maneuver'] as Map<String, dynamic>?) ?? {};
    final type = (maneuver['type'] as String?) ?? 'continue';
    final modifier = (maneuver['modifier'] as String?) ?? '';
    final name = (step['name'] as String?) ?? '';
    final distance = ((step['distance'] as num?) ?? 0).toDouble();

    String action;
    if (type == 'turn' && modifier.isNotEmpty) {
      action = 'Turn $modifier';
    } else if (type == 'roundabout') {
      action = 'Take the roundabout';
    } else if (type == 'arrive') {
      action = 'Arrive at destination';
    } else if (type == 'depart') {
      action = 'Start driving';
    } else {
      action = 'Continue';
    }

    final road = name.trim().isEmpty ? '' : ' onto $name';
    return '$action$road (${_formatDistance(distance)})';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double seconds) {
    final totalMinutes = (seconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dataCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search'),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onSearchPressed(),
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed:
                        (_isSearching ||
                            _isSearchingCarParks ||
                            _isRouting ||
                            _isLocating)
                        ? null
                        : _onSearchPressed,
                    child:
                        (_isSearching ||
                            _isSearchingCarParks ||
                            _isRouting ||
                            _isLocating)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Go'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => _setSpeechEnabled(!_speechEnabled),
                    tooltip: _speechEnabled
                        ? 'Turn speech off'
                        : 'Turn speech on',
                    icon: Icon(
                      _speechEnabled ? Icons.volume_up : Icons.volume_off,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _followUser = !_followUser;
                      });
                      if (_followUser) {
                        _mapController.move(_startLocation, 16);
                      }
                    },
                    tooltip: _followUser
                        ? 'Following your location'
                        : 'Center on you',
                    icon: Icon(
                      _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          retinaMode: RetinaMode.isHighDensity(context),
                          userAgentPackageName: 'com.example.setap',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.white,
                                strokeWidth: 9,
                              ),
                              Polyline(
                                points: _routePoints,
                                color: const Color(0xFF008752),
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _startLocation,
                              width: 22,
                              height: 22,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            Marker(
                              point: _selectedLocation,
                              width: 42,
                              height: 42,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF008752),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        RichAttributionWidget(
                          alignment: AttributionAlignment.bottomLeft,
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors © CARTO',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nearby car parks',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF008752),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Distance filters
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Min: ${_minDistance.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Slider(
                                  min: 0,
                                  max: _maxDistance,
                                  value: _minDistance,
                                  onChanged: (value) {
                                    setState(() {
                                      _minDistance = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Max: ${_maxDistance.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Slider(
                                  min: _minDistance,
                                  max: 50,
                                  value: _maxDistance,
                                  onChanged: (value) {
                                    setState(() {
                                      _maxDistance = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isSearchingCarParks)
                        const Center(child: CircularProgressIndicator())
                      else if (_searchedCarParks.isEmpty)
                        const Center(
                          child: Text('No car parks found in this range.'),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: _searchedCarParks.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 14),
                            itemBuilder: (context, index) {
                              final carPark = _searchedCarParks[index];

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(carPark.name),
                                subtitle: Text(_formatCarParkSubtitle(carPark)),
                                trailing: const Icon(Icons.navigation),
                                onTap: () =>
                                    _routeToCarParkByCoordinates(carPark),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationStep {
  final String instruction;
  final LatLng maneuverPoint;

  const _NavigationStep({
    required this.instruction,
    required this.maneuverPoint,
  });
}
