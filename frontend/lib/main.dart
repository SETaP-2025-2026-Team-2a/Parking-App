import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/cubit.dart';
import 'widgets/parking_timer.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'utils/theme_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _themeManager = widget.themeManager;
    // Register the setState callback so theme changes trigger rebuilds
    _themeManager.setOnThemeChanged(() {
      setState(() {});
    });
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Page',
      theme: _themeManager.lightTheme,
      darkTheme: _themeManager.darkTheme,
      themeMode: _themeManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: BlocProvider(create: (context) => DataCubit()..fetch(), child: const HomePage()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Pages for each tab
  final List<Widget> _pages = [
    const HomeTabContent(),
    const SearchTabContent(),
    const ProfileTabContent(),
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
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Home Tab Content
class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Parking Timer
            ParkingTimer(
              onSessionEnd: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Your parking session has ended')));
              },
              onExtend: (extension) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session extended by ${extension.inMinutes} minutes'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            // Parking spots list
            BlocBuilder<DataCubit, DataState>(
              builder: (context, state) {
                // loading
                if (state is DataFetchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // success
                else if (state is DataFetchSuccess) {
                  return Column(
                    children: state.data!.data
                        .map(
                          (spot) => ListTile(
                            title: Text(spot['name']),
                            subtitle: Text('Spaces: ${spot['spaces']} • Distance: ${spot['distance']}km'),
                          ),
                        )
                        .toList(),
                  );
                }
                // failure
                else if (state is DataFetchFailed) {
                  return Center(child: Text(state.message!));
                }
                // something unexpected
                return const Center(child: Text('Something went wrong'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Search Tab Content
class SearchTabContent extends StatelessWidget {
  const SearchTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}


