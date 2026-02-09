// screens/home_screen.dart - Combined version
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'add_meal_screen.dart';
import 'settings_screen.dart';
import 'food_scan_screen.dart';
import 'meals_history_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// Główny ekran aplikacji z bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;

  // Lista ekranów
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onAddMeal: () => _navigateToAddMeal()),
      const HistoryScreen(),
      AddMealScreen(onBack: () => _navigateBack()),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];
  }

  void _navigateToAddMeal() {
    setState(() {
      _currentIndex = 2;
    });
  }

  void _navigateToFoodScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodScanScreen()),
    );
  }

  void _navigateToMealsHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MealsHistoryScreen()),
    );
  }

  void _navigateBack() {
    setState(() {
      _currentIndex = 0;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        // AppBar z tytułem i przyciskiem motywu
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _isDarkMode ? AppTheme.darkSurface : AppTheme.white,
          title: const Text(
            '🩺 DexCom',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            // Meals History button
            IconButton(
              onPressed: _navigateToMealsHistory,
              icon: const Icon(Icons.restaurant_menu),
              tooltip: 'Meals History',
              color: AppTheme.primaryBlue,
            ),
            // Food Scan button
            IconButton(
              onPressed: _navigateToFoodScan,
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Scan Food',
              color: AppTheme.successGreen,
            ),
            // Sign Out button
            IconButton(
              onPressed: () async {
                // Wylogowanie z Firebase
                await AuthService().signOut();
                // Nawigacja obsługiwana przez StreamBuilder w MyApp
              },
              icon: Icon(
                Icons.logout,
                color: _isDarkMode ? AppTheme.lightGray : AppTheme.darkGray,
              ),
              tooltip: 'Sign Out',
            ),
            // Dark/Light mode toggle
            IconButton(
              onPressed: _toggleTheme,
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _isDarkMode ? AppTheme.lightGray : AppTheme.darkGray,
              ),
              tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
            ),
          ],
        ),
        // Zawartość - aktualny ekran
        body: IndexedStack(index: _currentIndex, children: _screens),
        // Bottom Navigation Bar
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: _isDarkMode ? AppTheme.darkSurface : AppTheme.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: _isDarkMode
              ? Colors.grey[400]
              : AppTheme.darkGray,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Text('📊', style: TextStyle(fontSize: 20)),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Text('📋', style: TextStyle(fontSize: 20)),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Text('🍽️', style: TextStyle(fontSize: 20)),
              label: 'Add Meal',
            ),
            BottomNavigationBarItem(
              icon: Text('📈', style: TextStyle(fontSize: 20)),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: Text('⚙️', style: TextStyle(fontSize: 20)),
              label: 'Settings',
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton(
            onPressed: _navigateToFoodScan,
            backgroundColor: AppTheme.successGreen,
            tooltip: 'Scan Food',
            child: const Icon(Icons.camera_alt, size: 28, color: AppTheme.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
