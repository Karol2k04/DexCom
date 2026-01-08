# Instrukcja Konfiguracji Firebase dla DexCom

## 1. Utwórz Projekt Firebase

1. Przejdź do [Firebase Console](https://console.firebase.google.com/)
2. Kliknij "Add project" lub "Dodaj projekt"
3. Podaj nazwę projektu (np. "DexCom")
4. (Opcjonalnie) Włącz Google Analytics
5. Kliknij "Create project"

## 2. Dodaj Aplikację Web

1. W Firebase Console wybierz swój projekt
2. Kliknij ikonę Web `</>` (dodaj aplikację Web)
3. Podaj nazwę aplikacji (np. "DexCom Web")
4. **ZAZNACZ** opcję "Firebase Hosting" (opcjonalnie)
5. Kliknij "Register app"

## 3. Skopiuj Konfigurację Firebase

Po zarejestrowaniu aplikacji zobaczysz konfigurację Firebase. Będzie wyglądać podobnie do tego:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyAbc123...",
  authDomain: "dexcom-xxxxx.firebaseapp.com",
  projectId: "dexcom-xxxxx",
  storageBucket: "dexcom-xxxxx.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123..."
};
```

## 4. Zaktualizuj Konfigurację w Projekcie

### A. Zaktualizuj `web/index.html`

Otwórz plik `d:\DexCom\web\index.html` i zastąp EXAMPLE wartości swoimi:

```javascript
const firebaseConfig = {
  apiKey: "TU_WKLEJ_API_KEY",
  authDomain: "TU_WKLEJ_AUTH_DOMAIN",
  projectId: "TU_WKLEJ_PROJECT_ID",
  storageBucket: "TU_WKLEJ_STORAGE_BUCKET",
  messagingSenderId: "TU_WKLEJ_MESSAGING_SENDER_ID",
  appId: "TU_WKLEJ_APP_ID"
};
```

### B. Zaktualizuj `lib/main.dart`

Otwórz plik `d:\DexCom\lib\main.dart` i w funkcji `main()` zastąp wartości w `FirebaseOptions`:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "TU_WKLEJ_API_KEY",
    authDomain: "TU_WKLEJ_AUTH_DOMAIN",
    projectId: "TU_WKLEJ_PROJECT_ID",
    storageBucket: "TU_WKLEJ_STORAGE_BUCKET",
    messagingSenderId: "TU_WKLEJ_MESSAGING_SENDER_ID",
    appId: "TU_WKLEJ_APP_ID",
  ),
);
```

## 5. Włącz Authentication w Firebase

1. W Firebase Console przejdź do **Authentication** (Uwierzytelnianie)
2. Kliknij "Get started" lub "Rozpocznij"
3. Przejdź do zakładki **Sign-in method**
4. Włącz następujące metody:
   - **Email/Password** - kliknij, włącz i zapisz
   - **Google** - kliknij, włącz, podaj email projektu i zapisz

### Konfiguracja Google Sign-In (dodatkowe kroki):

1. W ustawieniach Google Sign-In dodaj autoryzowane domeny:
   - `localhost` (dla developmentu)
   - Twoja domena produkcyjna (jeśli planujesz deploy)

## 6. Uruchom Aplikację

```bash
flutter run -d chrome
```

## 7. Testowanie

### Rejestracja nowego użytkownika:
1. Wprowadź email (np. `test@example.com`)
2. Wprowadź hasło (min. 6 znaków)
3. Kliknij "Utwórz konto"

### Logowanie:
1. Wprowadź zarejestrowany email
2. Wprowadź hasło
3. Kliknij "Zaloguj się"

### Google Sign-In:
1. Kliknij "Zaloguj przez Google"
2. Wybierz konto Google
3. Zatwierdź uprawnienia

### Reset hasła:
1. Wprowadź email w polu login
2. Kliknij "Zapomniałeś hasła?"
3. Sprawdź email z linkiem do resetowania

## 8. Sprawdź Użytkowników w Firebase Console

Po zarejestrowaniu możesz zobaczyć użytkowników w:
**Firebase Console → Authentication → Users**

## Troubleshooting

### Błąd: "Firebase: Error (auth/configuration-not-found)"
- Upewnij się, że skopiowałeś poprawną konfigurację z Firebase Console
- Sprawdź czy wartości w `web/index.html` i `lib/main.dart` są identyczne

### Błąd: "Firebase: Error (auth/unauthorized-domain)"
- W Firebase Console → Authentication → Settings → Authorized domains
- Dodaj domenę na której testujesz (np. `localhost`)

### Google Sign-In nie działa
- Upewnij się, że włączyłeś Google jako metodę logowania
- Sprawdź autoryzowane domeny w Firebase Console
- Na produkcji może być potrzebna dodatkowa konfiguracja OAuth

### Błąd: "Firebase: Error (auth/api-key-not-valid)"
- Sprawdź czy API Key jest poprawny
- Upewnij się, że nie ma spacji przed/po kluczu

## Bezpieczeństwo

⚠️ **WAŻNE**: 
- Nie commituj kluczy API do publicznego repozytorium
- Dodaj `web/index.html` do `.gitignore` jeśli zawiera wrażliwe dane
- Rozważ użycie zmiennych środowiskowych dla produkcji
- Włącz Firebase Security Rules dla dodatkowej ochrony

## Dodatkowe Funkcje (Opcjonalnie)

### Weryfikacja Email
Dodaj w `lib/services/auth_service.dart`:
```dart
Future<void> sendEmailVerification() async {
  await _auth.currentUser?.sendEmailVerification();
}
```

### Firestore Database
Jeśli chcesz przechowywać dane użytkowników:
1. Firebase Console → Firestore Database
2. Create database → Start in test mode
3. Dodaj pakiet: `cloud_firestore: ^5.5.0`

### Firebase Hosting (Deploy do produkcji)
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
flutter build web
firebase deploy
```
