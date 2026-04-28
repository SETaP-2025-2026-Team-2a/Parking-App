import 'dart:async';

import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'search_page.dart' as search;
import 'search_data/search.dart';
import 'user_addition/user_model.dart';

void main() {
  runApp(MyApp(themeManager: ThemeManager()));
}

class MyApp extends StatefulWidget {
  final ThemeManager themeManager;

  const MyApp({required this.themeManager, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeManager _themeManager;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _themeManager = widget.themeManager;
    _themeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

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
      theme: _themeManager.lightTheme,
      darkTheme: _themeManager.darkTheme,
      themeMode: _themeManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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

  late Duration _remainingDuration;
  late Duration _totalDuration;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _remainingDuration = const Duration(hours: 1, minutes: 0);
    _totalDuration = _remainingDuration;
    _startTimer();
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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _remainingDuration == Duration.zero) {
        return;
      }

      setState(() {
        final nextDuration = _remainingDuration - const Duration(seconds: 1);
        if (nextDuration <= Duration.zero) {
          _remainingDuration = Duration.zero;
          _isPaused = true;
          _timer?.cancel();
        } else {
          _remainingDuration = nextDuration;
        }
      });
    });
  }

  void _togglePause() {
    if (_remainingDuration == Duration.zero) {
      return;
    }

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _addThirtyMinutes() {
    setState(() {
      _remainingDuration += _extensionDuration;
      _totalDuration += _extensionDuration;
      if (_remainingDuration > Duration.zero && _timer == null) {
        _startTimer();
      }
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
    final pages = [
      HomePage(
        remainingTime: _formatDuration(_remainingDuration),
        progress: _totalDuration.inSeconds == 0
            ? 0.0
            : _remainingDuration.inSeconds / _totalDuration.inSeconds,
        isPaused: _isPaused,
        onPauseResume: _togglePause,
        onAddThirtyMinutes: _addThirtyMinutes,
      ),
      const search.SearchPage(),
      const HistoryPageWrapper(),
      ProfilePageWrapper(session: widget.session),
      SettingsTabContent(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
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
  final String remainingTime;
  final double progress;
  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onAddThirtyMinutes;

  const HomePage({
    super.key,
    required this.remainingTime,
    required this.progress,
    required this.isPaused,
    required this.onPauseResume,
    required this.onAddThirtyMinutes,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _nearbyRadiusKm = 5.0;
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
        radiusKm: _nearbyRadiusKm,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Expanded(
              flex: 3,
              child: ActiveStayWidget(
                remainingTime: widget.remainingTime,
                progress: widget.progress,
                isPaused: widget.isPaused,
                onPauseResume: widget.onPauseResume,
                onAddThirtyMinutes: widget.onAddThirtyMinutes,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nearby Car Parks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Builder(
                builder: (context) {
                  if (_isLoadingNearby) {
                    return const Center(child: CircularProgressIndicator());
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
                    return const Center(
                      child: Text('No nearby car parks found within 5 km'),
                    );
                  }

                  return ListView.builder(
                    itemCount: _nearbyCarParks.length,
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
  final double progress;
  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onAddThirtyMinutes;

  const ActiveStayWidget({
    super.key,
    required this.remainingTime,
    required this.progress,
    required this.isPaused,
    required this.onPauseResume,
    required this.onAddThirtyMinutes,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ACTIVE STAY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF008752),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    color: const Color(0xFF008752),
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFE9F4EE),
                  ),
                ),
                Text(
                  remainingTime,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onPauseResume,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onAddThirtyMinutes,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('+30 min'),
              ),
            ],
          ),
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
  const HistoryPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Color(0xFF008752)),
            SizedBox(height: 16),
            Text(
              'Your Parking History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('No history yet'),
          ],
        ),
      ),
    );
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
