import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/glucose_reading.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Pobierz wszystkich pacjentów (stream)
  Stream<List<UserProfile>> getPatientsStream({String? searchQuery}) {
    // Usunięto orderBy aby uniknąć potrzeby composite index
    Query query = _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient');

    return query.snapshots().map((snapshot) {
      debugPrint(
        '📊 Doctor: Znaleziono ${snapshot.docs.length} pacjentów w Firestore',
      );

      var patients = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('👤 Pacjent: ${data['email']} - role: ${data['role']}');
        return UserProfile.fromFirestore(data);
      }).toList();

      // Sortuj lokalnie po displayName
      patients.sort((a, b) => a.displayName.compareTo(b.displayName));

      // Filtruj po wyszukiwaniu lokalnie
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return patients.where((patient) {
          return patient.displayName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              patient.email.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return patients;
    });
  }

  /// Pobierz odczyty glukozy dla danego pacjenta
  Stream<List<GlucoseReading>> getPatientGlucoseReadings(String patientId) {
    return _firestore
        .collection('users')
        .doc(patientId)
        .collection('glucose_readings')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final timestamp = (data['timestamp'] as Timestamp);
            final dateTime = timestamp.toDate();
            return GlucoseReading(
              time:
                  '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
              timestamp: timestamp.millisecondsSinceEpoch,
              value: (data['value'] as num).toDouble(),
            );
          }).toList();
        });
  }

  /// Pobierz statystyki pacjenta (ostatnie 30 dni)
  Future<Map<String, dynamic>> getPatientStatistics(String patientId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final snapshot = await _firestore
        .collection('users')
        .doc(patientId)
        .collection('glucose_readings')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'count': 0,
        'inRange': 0,
        'timeInRange': 0.0,
      };
    }

    final readings = snapshot.docs
        .map((doc) => (doc.data()['value'] as num).toDouble())
        .toList();

    final average = readings.reduce((a, b) => a + b) / readings.length;
    final min = readings.reduce((a, b) => a < b ? a : b);
    final max = readings.reduce((a, b) => a > b ? a : b);
    final inRange = readings.where((r) => r >= 70 && r <= 180).length;
    final timeInRange = (inRange / readings.length) * 100;

    return {
      'average': average,
      'min': min,
      'max': max,
      'count': readings.length,
      'inRange': inRange,
      'timeInRange': timeInRange,
    };
  }
}
