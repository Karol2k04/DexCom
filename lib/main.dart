import 'package:flutter/material.dart';

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
      title: 'DexCom Login',
      // Wyłączenie bannera debug w prawym górnym rogu
      debugShowCheckedModeBanner: false,
      // Motyw aplikacji z zielonym kolorem głównym
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
        ),
        useMaterial3: true,
      ),
      // Startowa strona aplikacji - ekran logowania
      home: const LoginPage(),
    );
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
      // TODO: Implementacja logiki uwierzytelniania
    }
  }

  // Funkcja obsługi logowania przez Google
  void _handleGoogleLogin() {
    // Tutaj dodaj logikę logowania przez Google
    print('Google Login clicked');
    // TODO: Implementacja Google Sign-In
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
    return Scaffold(
      // Gradient tła w kolorach zielono-białych
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50), // Zielony góra
              Color(0xFF81C784), // Jaśniejszy zielony środek
              Colors.white, // Biały dół
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Nazwa firmy na górze
                    const Text(
                      'DexCom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Pole Login
                    TextFormField(
                      controller: _loginController,
                      decoration: InputDecoration(
                        labelText: 'Login',
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 2.5,
                          ),
                        ),
                      ),
                      // Walidacja - sprawdzenie czy pole nie jest puste
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
                      obscureText: true, // Ukrywanie znaków hasła
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 2.5,
                          ),
                        ),
                      ),
                      // Walidacja - sprawdzenie czy pole nie jest puste
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Proszę wprowadzić hasło';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Przycisk Login
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Separator "OR"
                    const Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.white70, thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.white70, thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Przycisk Login with Google z ikoną
                    OutlinedButton.icon(
                      onPressed: _handleGoogleLogin,
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 32,
                      ), // Ikona Google (lub użyj custom image)
                      label: const Text(
                        'Login with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Dolne opcje: Sign Up i Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Przycisk Sign Up - clickable text
                        TextButton(
                          onPressed: _handleSignUp,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        // Przycisk Forgot Password - clickable text
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text(
                            'Forgot my password',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
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
