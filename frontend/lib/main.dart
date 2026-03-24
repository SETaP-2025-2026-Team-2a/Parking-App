import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/cubit.dart';
import 'widgets/parking_timer.dart';
import 'pages/auth_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'utils/theme_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Home Page',
          theme: ThemeManager().lightTheme,
          darkTheme: ThemeManager().darkTheme,
          themeMode: ThemeManager().isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _username;
  String? _email;
  int _authPageVersion = 0;

  void _onAuthenticated({required String username, required String email}) {
    setState(() {
      _username = username;
      _email = email;
    });
  }

  void _onLogout() {
    setState(() {
      _username = null;
      _email = null;
      _authPageVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_username == null || _email == null) {
      return AuthPage(
        key: ValueKey('auth-$_authPageVersion'),
        onAuthenticated: _onAuthenticated,
      );
    }

    return BlocProvider(
      create: (context) => DataCubit()..fetch(),
      child: HomePage(
        username: _username!,
        email: _email!,
        onLogout: _onLogout,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String username;
  final String email;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.username,
    required this.email,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _handleLogout() {
    setState(() {
      _selectedIndex = 0;
    });
    widget.onLogout();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomeTabContent();
      case 1:
        return const SearchTabContent();
      case 2:
        return ProfileTabContent(
          userName: widget.username,
          userEmail: widget.email,
        );
      case 3:
        return SettingsTabContent(onLogout: _handleLogout);
      default:
        return const HomeTabContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildCurrentPage(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your parking session has ended'),
                  ),
                );
              },
              onExtend: (extension) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Session extended by ${extension.inMinutes} minutes',
                    ),
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
                            subtitle: Text(
                              'Spaces: ${spot['spaces']} • Distance: ${spot['distance']}km',
                            ),
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
