import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

// Punkt wejścia aplikacji - uruchamia główny widget
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      // Używamy AppTheme dla spójnego wyglądu
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Używamy StreamBuilder do obsługi stanu zalogowania
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // Ładowanie
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Jeśli użytkownik jest zalogowany - pokaż HomeScreen
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Jeśli niezalogowany - pokaż LoginPage
          return const LoginPage();
        },
      ),
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

  // Stan ładowania
  bool _isLoading = false;

  // Instancja serwisu autentykacji
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    // Zwolnienie zasobów kontrolerów po zamknięciu widoku
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Funkcja obsługi logowania standardowego
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.signInWithEmailAndPassword(
          email: _loginController.text.trim(),
          password: _passwordController.text,
        );
        // Nawigacja obsługiwana przez StreamBuilder w MyApp
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Funkcja obsługi logowania przez Google
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      // Nawigacja obsługiwana przez StreamBuilder w MyApp
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Funkcja obsługi przycisku rejestracji
  void _handleSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  // Funkcja obsługi przycisku przypomnij hasło
  Future<void> _handleForgotPassword() async {
    if (_loginController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wprowadź email, aby zresetować hasło'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_loginController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wysłano link do resetowania hasła'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        backgroundColor: _isDarkMode
            ? AppTheme.darkBackground
            : AppTheme.lightGray,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _isDarkMode ? AppTheme.darkSurface : AppTheme.white,
          title: const Text(
            'DexCom',
            style: TextStyle(
              color: AppTheme.primaryBlue,
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
                color: _isDarkMode ? AppTheme.lightGray : AppTheme.darkGray,
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
                      'Welcome to DexCom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? AppTheme.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDarkMode
                            ? Colors.grey[400]
                            : AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card z polami logowania
                    Card(
                      elevation: 0,
                      color: _isDarkMode ? AppTheme.darkCard : AppTheme.white,
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
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryBlue,
                                ),
                                filled: true,
                                fillColor: _isDarkMode
                                    ? AppTheme.darkSurface
                                    : AppTheme.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
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
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: AppTheme.primaryBlue,
                                ),
                                filled: true,
                                fillColor: _isDarkMode
                                    ? AppTheme.darkSurface
                                    : AppTheme.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
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
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign In',
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
                            color: _isDarkMode
                                ? Colors.grey[700]
                                : AppTheme.mediumGray,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : AppTheme.darkGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: _isDarkMode
                                ? Colors.grey[700]
                                : AppTheme.mediumGray,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Przycisk Login with Google
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isDarkMode
                            ? AppTheme.white
                            : AppTheme.darkGray,
                        backgroundColor: _isDarkMode
                            ? AppTheme.darkCard
                            : AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: _isDarkMode
                              ? Colors.grey[700]!
                              : AppTheme.mediumGray,
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
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
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
