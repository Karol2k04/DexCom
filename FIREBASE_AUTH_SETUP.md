# Firebase Authentication - Instrukcja konfiguracji

## Włączanie Email/Password Authentication w Firebase Console

1. Otwórz [Firebase Console](https://console.firebase.google.com/)
2. Wybierz swój projekt **DexCom**
3. W menu po lewej stronie kliknij **Authentication** (🔐)
4. Jeśli to pierwsze uruchomienie, kliknij **Get Started**
5. Przejdź do zakładki **Sign-in method**
6. Kliknij **Email/Password**
7. Włącz przełącznik **Enable**
8. Kliknij **Save**

## Włączanie Google Sign-In (opcjonalnie)

1. W tej samej zakładce **Sign-in method** kliknij **Google**
2. Włącz przełącznik **Enable**
3. Wybierz **Project support email** z listy rozwijanej
4. Kliknij **Save**

## Testowanie aplikacji

Aplikacja jest gotowa do:

✅ **Rejestracji nowych użytkowników** - kliknij "Utwórz konto"
- Wprowadź email i hasło (min. 6 znaków)
- Kliknij "Zaloguj się" lub ponownie "Utwórz konto"
- Użytkownik zostanie automatycznie zalogowany

✅ **Logowania istniejących użytkowników**
- Wprowadź email i hasło
- Kliknij "Zaloguj się"
- Po poprawnym zalogowaniu przekierowanie do HomeScreen

✅ **Resetowania hasła** - kliknij "Zapomniałeś hasła?"
- Wprowadź email w polu Login
- Kliknij "Zapomniałeś hasła?"
- Link do resetowania zostanie wysłany na email

✅ **Logowania przez Google** - kliknij przycisk Google
- Wybierz konto Google
- Automatyczne logowanie

✅ **Wylogowania**
- Po zalogowaniu kliknij ikonę wylogowania w prawym górnym rogu HomeScreen

## Sprawdzanie użytkowników w Firebase

1. Przejdź do **Authentication** → **Users**
2. Zobaczysz listę wszystkich zarejestrowanych użytkowników
3. Możesz ręcznie dodawać, edytować lub usuwać użytkowników

## Komunikaty błędów (po polsku)

Aplikacja wyświetla przyjazne komunikaty błędów:
- "Nie znaleziono użytkownika z podanym emailem"
- "Nieprawidłowe hasło"
- "Ten email jest już używany"
- "Hasło jest zbyt słabe"
- "Nieprawidłowy adres email"
- itd.

## Bezpieczeństwo

⚠️ **Ważne**: Hasła są bezpiecznie przechowywane przez Firebase (haszowanie + salt)
⚠️ **Produkcja**: Pamiętaj o ustawieniu Firebase Security Rules przed publikacją
