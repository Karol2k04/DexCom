# Deep Link Setup - DexCom Application

## Konfiguracja Deep Linking

### Redirect URI dla dostawców OAuth/API

Twoja aplikacja jest skonfigurowana z następującym deep linkiem:

```
myapp://dexcom/callback
```

**Podaj ten URL jako redirect_uri dla swojego dostawcy (np. Dexcom API, OAuth provider, itp.)**

---

## Struktura Deep Link

- **Scheme**: `myapp`
- **Host**: `dexcom`
- **Path**: `/callback`
- **Pełny URL**: `myapp://dexcom/callback`

### Przykłady z parametrami

```
myapp://dexcom/callback?code=AUTH_CODE&state=STATE_VALUE
myapp://dexcom/callback?token=ACCESS_TOKEN
```

---

## Konfiguracja dla różnych platform

### Android ✅
Skonfigurowane w:
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `MainActivity.kt` - obsługa deep linków

### iOS ✅
Skonfigurowane w:
- `ios/Runner/Info.plist`
- URL Scheme: `myapp`

---

## Testowanie Deep Links

### Na Androidzie:
```bash
# Metoda 1: ADB
adb shell am start -W -a android.intent.action.VIEW -d "myapp://dexcom/callback?code=test123"

# Metoda 2: Z przeglądarki
# Utwórz plik HTML i otwórz w przeglądarce:
```html
<a href="myapp://dexcom/callback?code=test123">Test Deep Link</a>
```

### Na iOS:
```bash
# Przez Simulator
xcrun simctl openurl booted "myapp://dexcom/callback?code=test123"

# Przez Safari
# Wpisz w pasku adresu: myapp://dexcom/callback?code=test123
```

---

## Użycie w kodzie Flutter

### 1. Inicjalizacja w main.dart

```dart
import 'services/deep_link_service.dart';

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _deepLinkService.initialize();
    
    _deepLinkService.deepLinkStream.listen((Uri uri) {
      print('Deep link otrzymany: $uri');
      
      // Pobierz parametry
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      
      if (code != null) {
        // Obsłuż authorization code
        handleAuthorizationCode(code);
      }
    });
  }
}
```

### 2. Przykład obsługi OAuth callback

```dart
Future<void> handleAuthorizationCode(String code) async {
  try {
    // Wymień kod na access token
    final response = await http.post(
      Uri.parse('https://api.dexcom.com/v2/oauth2/token'),
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': 'myapp://dexcom/callback',
        'client_id': 'YOUR_CLIENT_ID',
        'client_secret': 'YOUR_CLIENT_SECRET',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      // Zapisz token i kontynuuj...
    }
  } catch (e) {
    print('Błąd podczas wymiany kodu: $e');
  }
}
```

---

## Alternatywa: HTTPS Deep Links (App Links / Universal Links)

Niektórzy dostawcy wymagają HTTPS redirect URI. W takim przypadku możesz skonfigurować:

### Android App Links
1. Dodaj do AndroidManifest.xml:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="twojadomena.com"
        android:path="/callback" />
</intent-filter>
```

2. Umieść plik `assetlinks.json` na serwerze:
https://twojadomena.com/.well-known/assetlinks.json

### iOS Universal Links
1. Dodaj do Info.plist:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:twojadomena.com</string>
</array>
```

2. Umieść plik `apple-app-site-association` na serwerze:
https://twojadomena.com/.well-known/apple-app-site-association

---

## Troubleshooting

### Deep link nie działa na Androidzie
1. Sprawdź czy aplikacja ma `android:exported="true"` i `android:launchMode="singleTask"`
2. Zresetuj aplikację: `flutter clean && flutter pub get`
3. Odinstaluj i zainstaluj ponownie aplikację

### Deep link nie działa na iOS
1. Sprawdź czy CFBundleURLSchemes jest poprawnie skonfigurowane w Info.plist
2. Przebuduj projekt: `cd ios && pod install && cd ..`
3. Oczyść build: `flutter clean`

### Parametry nie są przetwarzane
1. Sprawdź czy `DeepLinkService` jest zainicjalizowany w `initState`
2. Upewnij się, że słuchasz na `deepLinkStream`
3. Sprawdź logi: `print(uri.queryParameters)`

---

## Bezpieczeństwo

⚠️ **Ważne wskazówki bezpieczeństwa:**

1. **Nigdy nie przechowuj client_secret w kodzie aplikacji mobilnej**
2. **Używaj PKCE (Proof Key for Code Exchange) dla OAuth**
3. **Waliduj parametr `state` aby zapobiec CSRF atakom**
4. **Używaj HTTPS dla komunikacji z API**

Przykład z PKCE:
```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String generateCodeVerifier() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64Url.encode(values).replaceAll('=', '');
}

String generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}
```

---

## Checklist przed deployment

- [ ] Deep link skonfigurowany w AndroidManifest.xml (main i debug)
- [ ] Deep link skonfigurowany w iOS Info.plist
- [ ] MainActivity.kt obsługuje deep linki
- [ ] DeepLinkService zaimplementowany i zainicjalizowany
- [ ] Testowane na Android (physical device lub emulator)
- [ ] Testowane na iOS (physical device lub simulator)
- [ ] Redirect URI podany dostawcy API
- [ ] Bezpieczna obsługa tokenów (PKCE, state validation)

---

## Przydatne linki

- [Flutter Deep Linking Documentation](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
