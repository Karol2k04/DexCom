import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Helper do stworzenia pierwszego admina
///
/// UŻYCIE:
/// 1. Zaimportuj ten plik gdzieś w aplikacji (np. w settings_screen.dart)
/// 2. Dodaj ukryty przycisk lub wywołaj metodę makeFirstAdmin()
/// 3. Podaj swój email
/// 4. Wyloguj się i zaloguj ponownie
///
/// UWAGA: Po stworzeniu pierwszego admina, USUŃ TEN PLIK lub zakomentuj kod!

class AdminHelper {
  /// Zmień użytkownika na admina po email
  static Future<void> makeAdmin(String email) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        debugPrint('❌ Nie znaleziono użytkownika o email: $email');
        return;
      }

      for (var doc in usersSnapshot.docs) {
        await doc.reference.update({
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Zmieniono rolę na admin dla: $email');
      }
    } catch (e) {
      debugPrint('❌ Błąd: $e');
    }
  }

  /// Widget z ukrytym przyciskiem do tworzenia admina
  /// Dodaj go gdzieś w SettingsScreen jako hidden feature
  static Widget buildHiddenAdminButton(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showAdminDialog(context);
      },
      child: const SizedBox(height: 50, width: 50),
    );
  }

  static void _showAdminDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stwórz Admina'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email użytkownika',
            hintText: 'user@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              await makeAdmin(emailController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sprawdź logi. Wyloguj/zaloguj się ponownie.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Zrób Adminem'),
          ),
        ],
      ),
    );
  }
}

/// ALTERNATYWNIE: Prosty standalone script
/// Możesz wywołać to w main.dart po inicjalizacji Firebase:
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///
///   // WYWOŁAJ RAZ I ZAKOMENTUJ!
///   // await AdminHelper.makeAdmin('twoj@email.com');
///
///   runApp(const MyApp());
/// }
