import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// Punkt wejścia aplikacji - uruchamia główny widget
void main() {
  runApp(const MyApp());
}

// Główny widget aplikacji - bezstanowy (stateless)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DexCom',
      // Wyłączenie bannera debug w prawym górnym rogu
      debugShowCheckedModeBanner: false,
      // Motyw aplikacji z niebieskim kolorem głównym (jak reszta aplikacji)
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
      // Startowa strona aplikacji - ekran logowania
      home: const LoginPageWrapper(),
    );
  }
}

// Wrapper dla LoginPage do eksportu
class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

// Widget strony logowania - stanowy (stateful) dla zarządzania stanem formularza
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Kontrolery tekstowe do zarządzania wartościami w polach login i hasło
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Klucz formularza do walidacji danych
  final _formKey = GlobalKey<FormState>();

  // Stan motywu (dark/light)
  bool _isDarkMode = false;

  @override
  void dispose() {
    // Zwolnienie zasobów kontrolerów po zamknięciu widoku
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Funkcja obsługi logowania standardowego
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // Tutaj dodaj logikę logowania
      print('Login: ${_loginController.text}');
      print('Password: ${_passwordController.text}');

      // Po udanym logowaniu - przejdź do głównej aplikacji
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // Funkcja obsługi logowania przez Google
  void _handleGoogleLogin() {
    // Tutaj dodaj logikę logowania przez Google
    print('Google Login clicked');

    // Po udanym logowaniu - przejdź do głównej aplikacji
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  // Funkcja obsługi przycisku rejestracji
  void _handleSignUp() {
    // Tutaj dodaj nawigację do strony rejestracji
    print('Sign Up clicked');
    // TODO: Nawigacja do ekranu rejestracji
  }

  // Funkcja obsługi przycisku przypomnij hasło
  void _handleForgotPassword() {
    // Tutaj dodaj nawigację do strony odzyskiwania hasła
    print('Forgot Password clicked');
    // TODO: Nawigacja do ekranu resetowania hasła
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

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
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          title: Text(
            'DexCom',
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Nazwa firmy
                    Text(
                      'Witaj w DexCom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Zaloguj się do swojego konta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card z polami logowania
                    Card(
                      elevation: 0,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Pole Login
                            TextFormField(
                              controller: _loginController,
                              decoration: InputDecoration(
                                labelText: 'Login',
                                hintText: 'Wprowadź login',
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.blue[600],
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue[600]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Proszę wprowadzić login';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Pole Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Hasło',
                                hintText: 'Wprowadź hasło',
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.blue[600],
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue[600]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Proszę wprowadzić hasło';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Przycisk Login
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Zaloguj się',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Separator "LUB"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'LUB',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Przycisk Login with Google
                    OutlinedButton.icon(
                      onPressed: _handleGoogleLogin,
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text(
                        'Zaloguj przez Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                        backgroundColor: isDark
                            ? Colors.grey[850]
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dolne opcje: Sign Up i Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _handleSignUp,
                          child: Text(
                            'Utwórz konto',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text(
                            'Zapomniałeś hasła?',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
