import 'dart:async';
import 'dart:convert';

import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/history_page.dart';
import 'utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'search_page.dart' as search;
import 'search_data/search.dart';
import 'user_addition/user_model.dart';

void main() {
  runApp(MyApp(themeManager: ThemeManager()));
}

enum ParkingSessionState { idle, active, ended }

class MyApp extends StatefulWidget {
  final ThemeManager themeManager;

  const MyApp({required this.themeManager, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AuthSession? _session;

  void _handleLoginSuccess(AuthSession session) {
    setState(() {
      _session = session;
    });
  }

  void _handleLogout() {
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking App',
      theme: widget.themeManager.lightTheme,
      home: _session == null
          ? LoginPage(onLoginSuccess: _handleLoginSuccess)
          : MainNavigation(session: _session!, onLogout: _handleLogout),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  final AuthSession session;
  final VoidCallback onLogout;

  const MainNavigation({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  static const Duration _extensionDuration = Duration(minutes: 30);
  static const Duration _maxSessionDuration = Duration(hours: 24);

  late Duration _remainingDuration;
  late Duration _totalDuration;
  Timer? _timer;
  ParkingSessionState _sessionState = ParkingSessionState.idle;
  CarPark? _activeCarPark;

  @override
  void initState() {
    super.initState();
    _remainingDuration = Duration.zero;
    _totalDuration = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool get _isSessionActive => _sessionState == ParkingSessionState.active;

  bool get _canReviewSession => _sessionState == ParkingSessionState.ended;

  // Run the active parking-session countdown and end the session when time runs out.
  void _startTimer() {
    _timer?.cancel();
    if (_remainingDuration <= Duration.zero) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionState != ParkingSessionState.active ||
          _remainingDuration == Duration.zero) {
        _timer?.cancel();
        return;
      }

      setState(() {
        final nextDuration = _remainingDuration - const Duration(seconds: 1);
        if (nextDuration <= Duration.zero) {
          _remainingDuration = Duration.zero;
          _sessionState = ParkingSessionState.ended;
          _timer?.cancel();
          _timer = null;
        } else {
          _remainingDuration = nextDuration;
        }
      });
    });
  }

  void _beginSession(Duration duration, CarPark carPark) {
    setState(() {
      _sessionState = ParkingSessionState.active;
      _activeCarPark = carPark;
      _remainingDuration = duration;
      _totalDuration = _remainingDuration;
      _startTimer();
    });
  }

  void _addThirtyMinutes() {
    if (!_isSessionActive) {
      return;
    }

    final newDuration = _remainingDuration + _extensionDuration;
    if (newDuration > _maxSessionDuration) {
      return;
    }

    setState(() {
      _remainingDuration = newDuration;
      _totalDuration += _extensionDuration;
      if (_remainingDuration > Duration.zero && _timer == null) {
        _startTimer();
      }
    });
  }

  Future<void> _cancelSession() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel stay?'),
          content: const Text(
            'Are you sure you want to cancel this parking session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    setState(() {
      _remainingDuration = Duration.zero;
      _sessionState = ParkingSessionState.ended;
      _timer?.cancel();
      _timer = null;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Keep each tab alive so navigation state and timers are preserved when switching screens.
    final pages = [
      HomePage(
        session: widget.session,
        remainingTime: _formatDuration(_remainingDuration),
        remainingDuration: _remainingDuration,
        maxSessionDuration: _maxSessionDuration,
        progress: _totalDuration.inSeconds == 0
            ? 0.0
            : _remainingDuration.inSeconds / _totalDuration.inSeconds,
        isSessionActive: _isSessionActive,
        canReviewSession: _canReviewSession,
        selectedCarPark: _activeCarPark,
        onCancelSession: _cancelSession,
        onAddThirtyMinutes: _addThirtyMinutes,
        onStartSession: (carPark, duration) async {
          _beginSession(duration, carPark);
        },
      ),
      const search.SearchPage(),
      HistoryPageWrapper(session: widget.session),
      ProfilePageWrapper(session: widget.session),
      SettingsTabContent(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF008752),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AuthSession session;
  final String remainingTime;
  final Duration remainingDuration;
  final Duration maxSessionDuration;
  final double progress;
  final bool isSessionActive;
  final bool canReviewSession;
  final CarPark? selectedCarPark;
  final VoidCallback onCancelSession;
  final VoidCallback onAddThirtyMinutes;
  final Future<void> Function(CarPark carPark, Duration duration)
  onStartSession;

  const HomePage({
    super.key,
    required this.session,
    required this.remainingTime,
    required this.remainingDuration,
    required this.maxSessionDuration,
    required this.progress,
    required this.isSessionActive,
    required this.canReviewSession,
    required this.selectedCarPark,
    required this.onCancelSession,
    required this.onAddThirtyMinutes,
    required this.onStartSession,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _allCarParksRadiusKm = 20000.0;
  final SearchService _searchService = SearchService(
    baseUrl: 'http://localhost:8080',
  );
  bool _isLoadingNearby = false;
  String? _nearbyError;
  List<CarPark> _nearbyCarParks = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyCarParks();
  }

  Future<void> _loadNearbyCarParks() async {
    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are off.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final results = await _searchService.searchWithinRadius(
        query: '',
        longitude: position.longitude,
        latitude: position.latitude,
        radiusKm: _allCarParksRadiusKm,
      );

      results.sort((a, b) => a.distance.compareTo(b.distance));

      if (!mounted) {
        return;
      }

      setState(() {
        _nearbyCarParks = results;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _nearbyError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNearby = false;
        });
      }
    }
  }

  Future<CarPark?> _promptForCarPark() async {
    if (_nearbyCarParks.isEmpty) {
      return null;
    }

    return showModalBottomSheet<CarPark>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose a car park',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _nearbyCarParks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final carPark = _nearbyCarParks[index];
                      final price =
                          (carPark.rawData['price'] as num?)?.toDouble() ??
                          (carPark.rawData['hourly_rate'] as num?)?.toDouble();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF008752),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(carPark.name),
                        subtitle: Text(
                          '${carPark.distance.toStringAsFixed(1)} km away'
                          '${price != null ? ' • £${price.toStringAsFixed(2)}/hr' : ''}',
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(carPark),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Duration?> _promptForDuration(CarPark carPark) async {
    final durationController = TextEditingController(text: '60');
    String? errorText;
    final price =
        (carPark.rawData['price'] as num?)?.toDouble() ??
        (carPark.rawData['hourly_rate'] as num?)?.toDouble();
    final spaces =
        (carPark.rawData['spaces'] as num?)?.toInt() ??
        (carPark.rawData['space_count'] as num?)?.toInt();

    final duration = await showDialog<Duration>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void setPresetMinutes(int minutes) {
              durationController.text = minutes.toString();
              setDialogState(() {
                errorText = null;
              });
            }

            return AlertDialog(
              title: Text(carPark.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${carPark.distance.toStringAsFixed(1)} km away'
                    '${price != null ? ' • £${price.toStringAsFixed(2)}/hr' : ''}'
                    '${spaces != null ? ' • $spaces spaces' : ''}',
                  ),
                  const SizedBox(height: 8),
                  const Text('How long do you want to park?'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minutes',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('30 min'),
                        onPressed: () => setPresetMinutes(30),
                      ),
                      ActionChip(
                        label: const Text('60 min'),
                        onPressed: () => setPresetMinutes(60),
                      ),
                      ActionChip(
                        label: const Text('90 min'),
                        onPressed: () => setPresetMinutes(90),
                      ),
                      ActionChip(
                        label: const Text('2 hrs'),
                        onPressed: () => setPresetMinutes(120),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final minutes = int.tryParse(
                      durationController.text.trim(),
                    );
                    if (minutes == null || minutes <= 0) {
                      setDialogState(() {
                        errorText = 'Enter a valid number of minutes';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(Duration(minutes: minutes));
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );

    durationController.dispose();
    return duration;
  }

  Future<void> _startNewSession() async {
    final chosenCarPark = await _promptForCarPark();
    if (!mounted || chosenCarPark == null) {
      return;
    }

    final duration = await _promptForDuration(chosenCarPark);
    if (!mounted || duration == null) {
      return;
    }

    await widget.onStartSession(chosenCarPark, duration);
  }

  Future<void> _showReviewSheet() async {
    double rating = 5;
    final commentController = TextEditingController();
    String? commentError;

    final targetCarPark =
        widget.selectedCarPark ??
        (_nearbyCarParks.isNotEmpty ? _nearbyCarParks.first : null);
    final targetName = targetCarPark?.name ?? 'this car park';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget buildStar(int index) {
              final filled = index < rating;
              return IconButton(
                onPressed: () {
                  setSheetState(() {
                    rating = index + 1;
                  });
                },
                icon: Icon(
                  Icons.star,
                  size: 34,
                  color: filled ? Colors.amber : Colors.grey.shade300,
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Review $targetName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Choose a star rating and leave a comment.'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, buildStar),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '${rating.toStringAsFixed(0)} / 5',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Comment',
                          hintText:
                              'Tell others what stood out about this car park',
                          border: const OutlineInputBorder(),
                          errorText: commentError,
                        ),
                        onChanged: (value) {
                          if (commentError != null && value.trim().isNotEmpty) {
                            setSheetState(() {
                              commentError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (targetCarPark == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: No car park selected'),
                                ),
                              );
                              Navigator.of(sheetContext).pop();
                              return;
                            }

                            final comment = commentController.text.trim();
                            if (comment.isEmpty) {
                              setSheetState(() {
                                commentError = 'Please enter a comment';
                              });
                              return;
                            }

                            try {
                              final reviewData = {
                                'title': targetCarPark.name,
                                'review': rating.toInt(),
                                'comment': comment,
                              };

                              final response = await http.post(
                                Uri.parse('http://localhost:8080/review'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode(reviewData),
                              );

                              if (!context.mounted) return;

                              if (response.statusCode == 200 ||
                                  response.statusCode == 201) {
                                Navigator.of(sheetContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Thanks for reviewing $targetName',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to submit review: ${response.statusCode}',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error submitting review: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text('Submit review'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CircularActionButton(icon: Icons.electric_car, label: 'EV'),
                CircularActionButton(
                  icon: Icons.accessible,
                  label: 'Accessible',
                ),
                CircularActionButton(icon: Icons.umbrella, label: 'Covered'),
                CircularActionButton(icon: Icons.money, label: '<£10'),
              ],
            ),
            const SizedBox(height: 24),
            ActiveStayWidget(
              remainingTime: widget.remainingTime,
              remainingDuration: widget.remainingDuration,
              maxSessionDuration: widget.maxSessionDuration,
              progress: widget.progress,
              isSessionActive: widget.isSessionActive,
              canReviewSession: widget.canReviewSession,
              onCancelSession: widget.onCancelSession,
              onAddThirtyMinutes: widget.onAddThirtyMinutes,
              onStartNewSession: _startNewSession,
              onReviewCarPark: _showReviewSheet,
            ),
            const SizedBox(height: 16),
            if (widget.selectedCarPark != null) ...[
              SelectedCarParkCard(carPark: widget.selectedCarPark!),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            const Text(
              'All Car Parks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                if (_isLoadingNearby) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_nearbyError != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_nearbyError!),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadNearbyCarParks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (_nearbyCarParks.isEmpty) {
                  return const Center(child: Text('No car parks found'));
                }

                return ListView.builder(
                  itemCount: _nearbyCarParks.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final carPark = _nearbyCarParks[index];
                    final id = carPark.id == 0 ? index + 1 : carPark.id;
                    final price =
                        (carPark.rawData['price'] as num?)?.toDouble() ??
                        (carPark.rawData['hourly_rate'] as num?)?.toDouble();

                    return PremiumCard(
                      locationId: 'P$id',
                      name: carPark.name,
                      distance: '${carPark.distance.toStringAsFixed(1)} km',
                      price: price != null
                          ? '£${price.toStringAsFixed(2)}/hr'
                          : 'Price n/a',
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const CircularActionButton({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF008752),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class ActiveStayWidget extends StatelessWidget {
  final String remainingTime;
  final Duration remainingDuration;
  final Duration maxSessionDuration;
  final double progress;
  final bool isSessionActive;
  final bool canReviewSession;
  final VoidCallback onCancelSession;
  final VoidCallback onAddThirtyMinutes;
  final VoidCallback onStartNewSession;
  final VoidCallback onReviewCarPark;

  const ActiveStayWidget({
    super.key,
    required this.remainingTime,
    required this.remainingDuration,
    required this.maxSessionDuration,
    required this.progress,
    required this.isSessionActive,
    required this.canReviewSession,
    required this.onCancelSession,
    required this.onAddThirtyMinutes,
    required this.onStartNewSession,
    required this.onReviewCarPark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialSize = (constraints.maxWidth * 0.58)
              .clamp(120.0, 180.0)
              .toDouble();
          final title = isSessionActive
              ? 'ACTIVE STAY'
              : canReviewSession
              ? 'SESSION ENDED'
              : 'NO ACTIVE SESSION';

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF008752),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: dialSize,
                height: dialSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: dialSize,
                      height: dialSize,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0, 1),
                        color: const Color(0xFF008752),
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE9F4EE),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isSessionActive ? remainingTime : '00:00:00',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isSessionActive ? null : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isSessionActive) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          (remainingDuration + const Duration(minutes: 30) <=
                              maxSessionDuration)
                          ? onAddThirtyMinutes
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('+30 min'),
                    ),
                    FilledButton.icon(
                      onPressed: onCancelSession,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                if (canReviewSession) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onReviewCarPark,
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Review car park'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartNewSession,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start New Session'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SelectedCarParkCard extends StatelessWidget {
  final CarPark carPark;

  const SelectedCarParkCard({super.key, required this.carPark});

  @override
  Widget build(BuildContext context) {
    final price =
        (carPark.rawData['price'] as num?)?.toDouble() ??
        (carPark.rawData['hourly_rate'] as num?)?.toDouble();
    final spaces =
        (carPark.rawData['spaces'] as num?)?.toInt() ??
        (carPark.rawData['space_count'] as num?)?.toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBEE4CD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected car park',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF008752),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            carPark.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('${carPark.distance.toStringAsFixed(1)} km away'),
          const SizedBox(height: 4),
          Text(price != null ? '£${price.toStringAsFixed(2)}/hr' : 'Price n/a'),
          if (spaces != null) ...[
            const SizedBox(height: 4),
            Text('$spaces spaces available'),
          ],
        ],
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  final String locationId;
  final String name;
  final String distance;
  final String price;

  const PremiumCard({
    super.key,
    required this.locationId,
    required this.name,
    required this.distance,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            locationId,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Text('$distance • $price'),
      ),
    );
  }
}

// Wrapper for HistoryPage
class HistoryPageWrapper extends StatelessWidget {
  final AuthSession session;

  const HistoryPageWrapper({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return HistoryTabContent(session: session);
  }
}

// Wrapper for ProfilePage
class ProfilePageWrapper extends StatelessWidget {
  final AuthSession session;

  const ProfilePageWrapper({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return ProfileTabContent(session: session);
  }
}
