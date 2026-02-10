// Przykład użycia Deep Link Service w Twojej aplikacji
// Dodaj ten kod do main.dart

//import 'services/deep_link_service.dart';

/*
PRZYKŁAD UŻYCIA W MAIN.DART:

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _deepLinkService.initialize();
    
    // Nasłuchuj na deep linki
    _deepLinkService.deepLinkStream.listen((Uri uri) {
      print('Otrzymano deep link: $uri');
      
      // Parsuj parametry
      final params = _deepLinkService.parseDeepLink(uri);
      if (params != null) {
        print('Parametry z deep linku: $params');
        
        // Przykład: obsługa OAuth callback
        if (uri.path == '/callback') {
          final code = params['code'];
          final state = params['state'];
          
          if (code != null) {
            // Tutaj obsłuż callback z OAuth providera
            print('Authorization code: $code');
            print('State: $state');
            
            // Nawiguj do odpowiedniego ekranu lub wywołaj funkcję
            _handleOAuthCallback(code, state);
          }
        }
      }
    });
  }

  void _handleOAuthCallback(String code, String? state) {
    // Implementacja obsługi OAuth callback
    // Na przykład: wymiana kodu na token
    print('Obsługa OAuth callback z kodem: $code');
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DexCom App',
      home: HomeScreen(),
    );
  }
}
*/

// REDIRECT URI DO PODANIA DOSTAWCY:
// Android & iOS: myapp://dexcom/callback
//
// Jeśli dostawca wymaga HTTPS (np. niektórzy OAuth providerzy):
// Możesz również użyć App Links (Android) / Universal Links (iOS)
// Przykład: https://twojadomena.com/callback
