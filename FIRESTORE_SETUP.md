# 🔥 Firestore Setup Guide - Instrukcja Wdrożenia

## ✅ Co zostało zaimplementowane:

### 1. **FirestoreService** (`lib/services/firestore_service.dart`)
- Zapisuje dane z CSV do Firestore
- Ładuje dane z Firestore przy starcie aplikacji
- Automatycznie oblicza i zapisuje statystyki dzienne
- Historia importów CSV
- Obsługa błędów i logowanie

### 2. **Struktura bazy danych:**
```
users/{userId}/
  ├── profile/{userId}           # Profil użytkownika
  ├── glucose_readings/{id}      # Odczyty glukozy z CSV
  ├── csv_imports/{importId}     # Historia importów
  └── statistics/daily_stats/dates/{date}  # Statystyki dzienne
```

### 3. **Security Rules** (`firestore.rules`)
- Każdy użytkownik ma dostęp tylko do swoich danych
- Walidacja typów danych i zakresów wartości
- Zabezpieczenia przed nieautoryzowanym dostępem

### 4. **Integracja z aplikacją:**
- `GlucoseProvider` teraz zapisuje dane do Firestore przy imporcie CSV
- Automatyczne ładowanie danych z Firestore po zalogowaniu
- Dane lokalne + backup w chmurze

---

## 🚀 Kroki wdrożenia w Firebase Console:

### Krok 1: Firebase Console - Firestore Database

1. Przejdź do [Firebase Console](https://console.firebase.google.com/)
2. Wybierz swój projekt
3. Z menu po lewej wybierz **"Firestore Database"**
4. Kliknij **"Create database"**

### Krok 2: Wybór trybu zabezpieczeń

**Wybierz: "Start in production mode"**
- Security rules będą od razu aktywne
- Bezpieczniejsze niż tryb testowy

### Krok 3: Wybór lokalizacji

Wybierz region najbliższy użytkownikom, np.:
- **europe-west3 (Frankfurt)** - dla Europy
- **us-central1 (Iowa)** - dla USA

⚠️ **UWAGA:** Lokalizacji nie można zmienić później!

### Krok 4: Wdrożenie Security Rules

1. W Firestore Database, przejdź do zakładki **"Rules"**
2. Skopiuj zawartość pliku `firestore.rules` z projektu
3. Wklej do edytora reguł w Firebase Console
4. Kliknij **"Publish"**

### Krok 5: Utworzenie indeksów (opcjonalne)

Firebase może automatycznie sugerować indeksy podczas użytkowania.
Jeśli zobaczysz błąd w konsoli z linkiem do utworzenia indeksu - kliknij go.

Możesz też utworzyć indeksy z góry:

1. Przejdź do zakładki **"Indexes"**
2. Kliknij **"Add index"**
3. Dodaj następujące indeksy:

**Indeks 1: glucose_readings - po timestamp**
- Collection: `glucose_readings`
- Fields:
  - `timestamp` - Descending
  - `__name__` - Ascending
- Query scope: Collection

**Indeks 2: glucose_readings - po timestamp z filtrem**
- Collection: `glucose_readings`
- Fields:
  - `timestamp` - Ascending
  - `timestamp` - Descending
  - `__name__` - Ascending
- Query scope: Collection group

### Krok 6: Testowanie w aplikacji

1. Uruchom aplikację
2. Zaloguj się
3. Zaimportuj plik CSV
4. Sprawdź w Firebase Console czy dane się zapisały:
   - Firestore Database → Data
   - Powinieneś zobaczyć: `users/{uid}/glucose_readings/...`

---

## 🔍 Weryfikacja w Firebase Console:

### 1. Sprawdź strukturę danych:
```
users/
  └── {twoje_uid}/
      ├── glucose_readings/
      │   ├── {reading_id_1}
      │   ├── {reading_id_2}
      │   └── ...
      ├── csv_imports/
      │   └── import_xxxxx/
      └── statistics/
          └── daily_stats/
              └── dates/
                  ├── 2026-01-14/
                  └── 2026-01-15/
```

### 2. Przykładowy dokument `glucose_reading`:
```json
{
  "id": "abc123",
  "timestamp": "2026-01-15T08:30:00Z",
  "timestampString": "2026-01-15T08:30:00.000Z",
  "value": 120,
  "eventType": "EGV",
  "source": "csv",
  "importId": "import_1234567890",
  "createdAt": "2026-01-15T16:00:00Z"
}
```

### 3. Przykładowy dokument `daily_stats`:
```json
{
  "date": "2026-01-15",
  "avgGlucose": 125.3,
  "timeInRange": 78,
  "readingsCount": 288,
  "lowCount": 12,
  "highCount": 35,
  "calculatedAt": "2026-01-15T23:59:00Z"
}
```

---

## 📱 Jak działa w aplikacji:

### 1. **Przy logowaniu:**
```dart
// main.dart wywołuje:
await firestoreService.initializeUserProfile(user);
await glucoseProvider.loadDataFromFirestore();
```
- Tworzy profil użytkownika (jeśli nie istnieje)
- Ładuje wszystkie zapisane dane z Firestore

### 2. **Przy imporcie CSV:**
```dart
// GlucoseProvider.importFromCsv() wywołuje:
await _firestoreService.saveGlucoseReadingsFromCsv(
  readings: readings,
  fileName: fileName,
);
```
- Parsuje CSV
- Zapisuje do Firestore (batch write - szybkie)
- Oblicza i zapisuje statystyki
- Aktualizuje lokalny state

### 3. **Przy wylogowaniu:**
- Dane pozostają w Firestore
- Po ponownym zalogowaniu są automatycznie ładowane

---

## 🛡️ Security Rules - Co robią:

### ✅ Pozwalają:
- Użytkownikowi odczytywać/zapisywać **TYLKO swoje** dane
- Tworzenie nowych odczytów glukozy z walidacją (0-500 mg/dL)
- Zapisywanie statystyk z prawidłowymi polami
- Historię importów CSV

### ❌ Blokują:
- Dostęp do danych innych użytkowników
- Zapis nieprawidłowych wartości (np. glukoza = -50)
- Zapis dokumentów bez wymaganych pól
- Niezalogowanych użytkowników

---

## 🔧 Przydatne komendy do testowania:

### 1. Sprawdź czy Firestore jest podłączony:
```dart
// W aplikacji możesz dodać debug button:
ElevatedButton(
  onPressed: () async {
    final hasData = await FirestoreService().hasExistingData();
    print('Has data in Firestore: $hasData');
  },
  child: Text('Check Firestore'),
)
```

### 2. Wyczyść wszystkie dane (do testów):
```dart
// UWAGA: To usunie WSZYSTKIE dane użytkownika!
await FirestoreService().deleteAllUserData();
```

### 3. Zobacz historię importów:
```dart
final history = await FirestoreService().getImportHistory();
print('Import history: $history');
```

---

## 📊 Monitorowanie w Firebase Console:

### 1. **Usage Dashboard:**
- Firestore Database → Usage
- Zobacz ile dokumentów, odczytów, zapisów używasz
- Sprawdź czy nie przekraczasz limitów darmowego planu

### 2. **Spark Plan (darmowy) limity:**
- 1 GB przechowywania
- 50,000 odczytów dziennie
- 20,000 zapisów dziennie
- 20,000 usunięć dziennie

⚠️ **Import 1000 odczytów = 1000 zapisów + ~30 zapisów statystyk**

### 3. **Logs & Monitoring:**
- Cloud Functions → Logs (jeśli będziesz używać Cloud Functions)
- Sprawdzaj błędy Security Rules w zakładce Rules → Simulator

---

## 🎯 Następne kroki (opcjonalne rozszerzenia):

### 1. **Real-time synchronizacja:**
```dart
// Użyj stream zamiast jednorazowego ładowania:
_firestoreService.glucoseReadingsStream().listen((readings) {
  // Automatyczna aktualizacja UI przy zmianie danych
});
```

### 2. **Offline persistence:**
```dart
// W main.dart przed Firebase.initializeApp():
await FirebaseFirestore.instance.enablePersistence();
// Dane będą dostępne offline!
```

### 3. **Cloud Functions (automatyzacja):**
- Automatyczne obliczanie statystyk po dodaniu odczytu
- Wysyłanie powiadomień przy niskiej/wysokiej glukozie
- Eksport danych do PDF

### 4. **Backups:**
- Firebase Console → Firestore → Import/Export
- Można exportować dane do Google Cloud Storage
- Zalecane: cotygodniowe backupy

---

## ✅ Checklist wdrożenia:

- [ ] Utworzyłem Firestore Database w Firebase Console
- [ ] Wybrałem region (np. europe-west3)
- [ ] Wdrożyłem Security Rules z pliku `firestore.rules`
- [ ] Uruchomiłem `flutter pub get` (cloud_firestore zainstalowany)
- [ ] Zaimportowałem CSV w aplikacji
- [ ] Sprawdziłem w Firebase Console czy dane są zapisane
- [ ] Wylogowałem się i zalogowałem ponownie - dane nadal są
- [ ] Security Rules działają (nie widzę danych innych użytkowników)

---

## 🆘 Troubleshooting:

### Problem: "PERMISSION_DENIED"
**Rozwiązanie:** 
1. Sprawdź czy Security Rules są wdrożone
2. Sprawdź czy użytkownik jest zalogowany
3. Sprawdź w Firebase Console → Rules → Simulator

### Problem: "Index required"
**Rozwiązanie:**
- Kliknij link w błędzie - Firebase automatycznie utworzy indeks
- Poczekaj 1-2 minuty na budowę indeksu

### Problem: Dane się nie zapisują
**Rozwiązanie:**
1. Sprawdź logi w konsoli: `debugPrint` messages
2. Sprawdź czy Firebase jest zainicjalizowany w `main.dart`
3. Sprawdź internet connection

### Problem: Wolne ładowanie
**Rozwiązanie:**
- Włącz offline persistence
- Dodaj indeksy dla często używanych zapytań
- Ogranicz liczbę ładowanych dokumentów (`.limit(100)`)

---

## 📝 Podsumowanie:

✅ **Zaimplementowano:**
- ✅ FirestoreService z pełną obsługą CRUD
- ✅ Automatyczny zapis przy imporcie CSV
- ✅ Ładowanie danych po zalogowaniu
- ✅ Security Rules chroniące dane użytkownika
- ✅ Statystyki dzienne
- ✅ Historia importów

🎉 **Twoje dane z CSV są teraz bezpiecznie przechowywane w chmurze!**

Po wylogowaniu i ponownym zalogowaniu wszystkie dane będą dostępne.
