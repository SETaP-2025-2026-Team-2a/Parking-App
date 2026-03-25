import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/cubit.dart';
import 'widgets/parking_timer.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'search_page.dart' as search;

void main() {
  runApp(const ParkingApp());
}

class ParkingApp extends StatelessWidget {
  const ParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking App',
      theme: ThemeData(
        fontFamily: 'Ubuntu',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF008752)),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const search.SearchPage(),
    const HistoryPageWrapper(),
    const ProfilePageWrapper(),
    const SettingsTabContent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final progress = _totalDuration.inSeconds == 0
        ? 0.0
        : _remainingDuration.inSeconds / _totalDuration.inSeconds;

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
            // Hero Zone
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
            // Active Stay Widget
            Expanded(
              flex: 3,
              child: ActiveStayWidget(
                remainingTime: _formatDuration(_remainingDuration),
                progress: progress,
                isPaused: _isPaused,
                onPauseResume: _togglePause,
                onAddThirtyMinutes: _addThirtyMinutes,
              ),
            ),
            const SizedBox(height: 16),
            // Nearby Car Parks
            const Text(
              'Nearby Car Parks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return const PremiumCard(
                    locationId: '1234',
                    name: 'Car Park Name',
                    distance: '0.5 miles',
                    price: '£2.50/hr',
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
  const ProfilePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileTabContent();
  }
}

