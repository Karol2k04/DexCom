# System Ról Użytkowników - DexCom App

## 🎯 Przegląd Systemu

Aplikacja DexCom ma teraz 3 role użytkowników:

### 👤 **PATIENT** (Pacjent)
- Domyślna rola przy rejestracji
- Dostęp do swojego dashboardu z danymi glukozy
- Import CSV, dodawanie posiłków, statystyki
- Ekran: `HomeScreen`

### ⚕️ **DOCTOR** (Lekarz)
- Widzi listę wszystkich pacjentów
- Może przeglądać dane glukozy pacjentów
- Statystyki i historia odczytów pacjentów
- Ekran: `DoctorDashboardScreen`

### 👑 **ADMIN** (Administrator)
- Widzi WSZYSTKICH użytkowników (patients, doctors, admins)
- **Może zmieniać role użytkowników**
- Wyszukiwanie po email/nazwie
- Statystyki systemu
- Ekran: `AdminDashboardScreen`

---

## 🔐 Jak Działa System Bezpieczeństwa?

### 1. **Rejestracja**
- Każdy nowy użytkownik jest automatycznie `patient`
- Nie można wybrać roli podczas rejestracji
- Role przypisuje **tylko Admin**

### 2. **Firestore Security Rules**
- **Czytanie profili**: Każdy zalogowany (dla lekarzy/adminów)
- **Tworzenie profilu**: Tylko swój, tylko jako `patient`
- **Zmiana roli**: **TYLKO ADMIN** może zmienić rolę
- **Dane glukozy**: Właściciel full access, lekarze/adminy tylko odczyt

### 3. **Routing (main.dart)**
```dart
if (profile.isAdmin) {
  return AdminDashboardScreen();
} else if (profile.isDoctor) {
  return DoctorDashboardScreen();
} else {
  return HomeScreen(); // Patient
}
```

---

## 📝 Jak Stworzyć Pierwszego Admina?

### **Opcja 1: Manualnie w Firebase Console**
1. Wejdź na Firebase Console → Firestore Database
2. Znajdź kolekcję `users`
3. Wybierz swoje konto użytkownika
4. Edytuj dokument i dodaj/zmień pole:
   ```
   role: "admin"
   ```
5. Wyloguj się i zaloguj ponownie - będziesz miał panel admina

### **Opcja 2: Przez kod (temporary script)**
```dart
// Dodaj to tymczasowo w main.dart aby zrobić siebie adminem
Future<void> makeAdmin(String email) async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .get();
  
  if (usersSnapshot.docs.isNotEmpty) {
    await usersSnapshot.docs.first.reference.update({'role': 'admin'});
    print('✅ Made $email an admin');
  }
}

// Wywołaj w initState lub onPressed:
await makeAdmin('twoj@email.com');
```

---

## 🛠️ Workflow Użycia

### Jako Admin:
1. Zaloguj się (musisz już być adminem)
2. Panel admina pokazuje:
   - Statystyki (ile pacjentów, lekarzy, adminów)
   - Lista wszystkich użytkowników
   - Search bar (szukaj po email lub nazwie)
3. Kliknij na użytkownika → dialog wyboru roli
4. Wybierz nową rolę (patient/doctor/admin)
5. Użytkownik musi się wylogować i zalogować aby zobaczyć nowy ekran

### Jako Doctor:
1. Admin musi zmienić Twoją rolę na `doctor`
2. Wyloguj się i zaloguj ponownie
3. Zobaczysz `DoctorDashboardScreen`
4. Lista wszystkich pacjentów (tylko role=patient)
5. Kliknij na pacjenta → szczegóły + statystyki + odczyty glukozy

### Jako Patient:
1. Zarejestruj się normalnie
2. Standardowy ekran `HomeScreen`
3. Dashboard, import CSV, statystyki, etc.

---

## 📂 Struktura Plików

```
lib/
├── models/
│   └── user_profile.dart           # Model z enum UserRole
├── services/
│   ├── admin_service.dart          # Metody dla admina
│   ├── doctor_service.dart         # Metody dla lekarza
│   └── firestore_service.dart      # Zmodyfikowane (role=patient)
├── screens/
│   ├── admin/
│   │   └── admin_dashboard_screen.dart
│   ├── doctor/
│   │   ├── doctor_dashboard_screen.dart
│   │   └── patient_details_screen.dart
│   └── home_screen.dart            # Patient screen
└── main.dart                       # Routing bazowany na roli
```

---

## 🚀 Deploy Firestore Rules

**WAŻNE**: Musisz wgrać nowe Firestore Rules na Firebase!

### Firebase CLI:
```bash
firebase deploy --only firestore:rules
```

### Lub manualnie:
1. Firebase Console → Firestore Database → Rules
2. Skopiuj zawartość z `firestore.rules`
3. Publish changes

---

## 🧪 Testing

### Test 1: Sprawdź domyślną rolę
1. Zarejestruj nowego użytkownika
2. Sprawdź Firestore - powinien mieć `role: "patient"`

### Test 2: Admin zmienia rolę
1. Zaloguj się jako admin
2. Znajdź użytkownika
3. Zmień na `doctor`
4. Zaloguj się jako ten użytkownik - powinien zobaczyć doctor dashboard

### Test 3: Security Rules
1. Spróbuj zmienić rolę przez kod (nie będąc adminem) - powinno się nie udać
2. Lekarz próbuje edytować dane pacjenta - powinien mieć tylko odczyt

---

## 🐛 Common Issues

### Problem: "Nie widzę admin panelu mimo że mam role=admin"
**Rozwiązanie**: Wyloguj się i zaloguj ponownie

### Problem: "Cannot read property 'role' of undefined"
**Rozwiązanie**: Firestore Rules próbują czytać rolę - upewnij się że:
- Wszystkie użytkownicy mają pole `role`
- Firestore Rules są wgrane na Firebase

### Problem: "Permission denied"
**Rozwiązanie**: Wgraj nowe Firestore Rules z `firestore.rules`

---

## 📊 Firestore Structure

```
users/
  {userId}/
    - uid: string
    - email: string
    - displayName: string
    - role: "patient" | "doctor" | "admin"  ← NOWE
    - createdAt: timestamp
    - lastLogin: timestamp
    - updatedAt: timestamp (gdy admin zmienia rolę)
    - updatedBy: userId (kto zmienił rolę)
    
    glucose_readings/  (subcollection)
      {readingId}/
        - timestamp, value, etc...
    
    meals/  (subcollection)
      ...
```

---

## 🔒 Security Best Practices

✅ **Zrobione:**
- Role domyślnie `patient`
- Tylko admin może zmieniać role
- Firestore Rules zapobiegają samowolnej zmianie roli
- Lekarze mają tylko READ access do danych pacjentów

⚠️ **Do rozważenia w przyszłości:**
- Audit log (kto i kiedy zmienił rolę)
- Email notification dla użytkownika gdy zmieniono jego rolę
- Multi-factor auth dla adminów
- Rate limiting na zmiany ról

---

## 📞 Support

Jeśli coś nie działa:
1. Sprawdź Firestore Rules
2. Sprawdź czy użytkownik ma pole `role` w Firestore
3. Wyloguj/zaloguj ponownie
4. Sprawdź console logs (debugPrint)
