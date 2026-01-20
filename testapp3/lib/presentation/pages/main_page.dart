import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_config.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../bloc/index.dart';
import 'home_page.dart';
import '../../screens/profile_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const InitializeHomeEvent());
  }

  final List<Widget> _pages = [
    const HomePage(viewType: HomeViewType.dashboard),
    const HomePage(viewType: HomeViewType.analysis),
    const HomePage(viewType: HomeViewType.water),
    const HomePage(viewType: HomeViewType.tips),
    const ProfileScreen(showAppBar: false),
  ];

  final List<String> _titles = [
    AppConfig.appName,
    'Health Analysis',
    'Water Log',
    'Daily Health Tips',
    'User Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppTheme.secondaryBackground,
        elevation: 0,
        actions: [
          if (_currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.directions_walk),
              tooltip: 'Steps',
              onPressed: () => Navigator.pushNamed(context, Routes.steps),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed:
                  () => Navigator.pushNamed(context, Routes.notifications),
            ),
          ],
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_rounded),
              label: 'Water',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_rounded),
              label: 'Tips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
