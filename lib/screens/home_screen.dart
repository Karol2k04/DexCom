import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'add_meal_screen.dart';
import 'settings_screen.dart';
import '../services/auth_service.dart';

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
      HistoryScreen(),
      AddMealScreen(onBack: () => _navigateBack()),
      StatisticsScreen(),
      const SettingsScreen(),
    ];
  }

  void _navigateToAddMeal() {
    setState(() {
      _currentIndex = 2;
    });
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
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.light(
          primary: Colors.blue[600]!,
          secondary: Colors.green[600]!,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[400]!,
          secondary: Colors.green[400]!,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        // AppBar z tytułem i przyciskiem motywu
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text(
            'DexCom',
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Przycisk wylogowania
            IconButton(
              onPressed: () async {
                // Wylogowanie z Firebase
                await AuthService().signOut();
                // Nawigacja obs\u0142ugiwana przez StreamBuilder w MyApp
              },
              icon: Icon(
                Icons.logout,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              tooltip: 'Sign Out',
            ),
            // Przycisk dark/light mode
            IconButton(
              onPressed: _toggleTheme,
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
            ),
          ],
        ),
        // Zawartość - aktualny ekran
        body: IndexedStack(index: _currentIndex, children: _screens),
        // Bottom Navigation Bar
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: BottomAppBar(
            color: _isDarkMode ? Colors.grey[850] : Colors.white,
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Dashboard
                _buildNavButton(index: 0, icon: Icons.home, label: 'Dashboard'),
                // Historia
                _buildNavButton(
                  index: 1,
                  icon: Icons.history,
                  label: 'History',
                ),
                // Dodaj posiłek (FAB)
                _buildCenterFAB(),
                // Statystyki
                _buildNavButton(
                  index: 3,
                  icon: Icons.bar_chart,
                  label: 'Statistics',
                ),
                // Ustawienia
                _buildNavButton(
                  index: 4,
                  icon: Icons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Przycisk nawigacji
  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Colors.blue
        : (_isDarkMode ? Colors.grey[400] : Colors.grey[500]);

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Centralny FAB (Floating Action Button)
  Widget _buildCenterFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        backgroundColor: Colors.blue[600],
        elevation: 4,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}
