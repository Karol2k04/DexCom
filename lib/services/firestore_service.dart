import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/glucose_reading.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // ========== SAVE OPERATIONS ==========

  /// Save glucose readings from CSV import to Firestore
  Future<String> saveGlucoseReadingsFromCsv({
    required List<GlucoseReading> readings,
    required String fileName,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated. Please log in first.');
    }

    final batch = _firestore.batch();
    final importId = 'import_${DateTime.now().millisecondsSinceEpoch}';

    try {
      debugPrint('Starting Firestore save for ${readings.length} readings...');

      // 1. Save each glucose reading
      for (final reading in readings) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('glucose_readings')
            .doc();

        batch.set(docRef, {
          'id': docRef.id,
          'timestamp': Timestamp.fromDate(
            DateTime.fromMillisecondsSinceEpoch(reading.timestamp),
          ),
          'timestampString': DateTime.fromMillisecondsSinceEpoch(
            reading.timestamp,
          ).toIso8601String(),
          'value': reading.value,
          'eventType': 'EGV',
          'source': 'csv',
          'importId': importId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Save import record
      final importDocRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('csv_imports')
          .doc(importId);

      final sortedReadings = List<GlucoseReading>.from(readings)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      batch.set(importDocRef, {
        'importId': importId,
        'fileName': fileName,
        'importDate': FieldValue.serverTimestamp(),
        'recordsImported': readings.length,
        'dateRange': {
          'start': Timestamp.fromDate(
            DateTime.fromMillisecondsSinceEpoch(sortedReadings.first.timestamp),
          ),
          'end': Timestamp.fromDate(
            DateTime.fromMillisecondsSinceEpoch(sortedReadings.last.timestamp),
          ),
        },
        'status': 'success',
      });

      // Commit batch
      await batch.commit();
      debugPrint(
        '✅ Successfully saved ${readings.length} readings to Firestore',
      );

      // 3. Update statistics after successful import
      await _updateDailyStatistics(readings);

      return importId;
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');

      // Log failed import
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('csv_imports')
            .doc(importId)
            .set({
              'importId': importId,
              'fileName': fileName,
              'importDate': FieldValue.serverTimestamp(),
              'status': 'failed',
              'error': e.toString(),
            });
      } catch (logError) {
        debugPrint('Failed to log error: $logError');
      }

      rethrow;
    }
  }

  // ========== READ OPERATIONS ==========

  /// Get glucose readings for a specific period
  Future<List<GlucoseReading>> getGlucoseReadings({
    required DateTime startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('glucose_readings')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .orderBy('timestamp', descending: true);

    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp).toDate();

      return GlucoseReading(
        value: (data['value'] as num).toDouble(),
        time: _formatTime(timestamp),
        timestamp: timestamp.millisecondsSinceEpoch,
      );
    }).toList();
  }

  /// Get all glucose readings (for offline use)
  Future<List<GlucoseReading>> getAllGlucoseReadings() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('Loading all glucose readings from Firestore...');

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('glucose_readings')
        .orderBy('timestamp', descending: true)
        .get();

    debugPrint('Loaded ${snapshot.docs.length} readings from Firestore');

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();

      return GlucoseReading(
        value: (data['value'] as num).toDouble(),
        time: _formatTime(timestamp),
        timestamp: timestamp.millisecondsSinceEpoch,
      );
    }).toList();
  }

  /// Stream glucose readings in real-time
  Stream<List<GlucoseReading>> glucoseReadingsStream({
    DateTime? startDate,
    int limit = 100,
  }) {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('glucose_readings')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startDate != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        return GlucoseReading(
          value: (data['value'] as num).toDouble(),
          time: _formatTime(timestamp),
          timestamp: timestamp.millisecondsSinceEpoch,
        );
      }).toList();
    });
  }

  /// Get CSV import history
  Future<List<Map<String, dynamic>>> getImportHistory() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('csv_imports')
        .orderBy('importDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ========== STATISTICS ==========

  /// Update daily statistics after CSV import
  Future<void> _updateDailyStatistics(List<GlucoseReading> readings) async {
    if (_userId == null) return;

    debugPrint('Updating daily statistics...');

    // Group readings by date
    final Map<String, List<GlucoseReading>> readingsByDate = {};
    for (final reading in readings) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
      final dateKey = _formatDateKey(timestamp);
      readingsByDate.putIfAbsent(dateKey, () => []).add(reading);
    }

    // Calculate and save statistics for each date
    final batch = _firestore.batch();

    for (final entry in readingsByDate.entries) {
      final date = entry.key;
      final dayReadings = entry.value;

      final avgGlucose =
          dayReadings.map((r) => r.value).reduce((a, b) => a + b) /
          dayReadings.length;

      final inRange = dayReadings.where((r) => r.value >= 70 && r.value <= 180);
      final timeInRange = (inRange.length / dayReadings.length * 100).round();

      final lowCount = dayReadings.where((r) => r.value < 70).length;
      final highCount = dayReadings.where((r) => r.value > 180).length;

      final statsDocRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('statistics')
          .doc('daily_stats')
          .collection('dates')
          .doc(date);

      batch.set(statsDocRef, {
        'date': date,
        'avgGlucose': avgGlucose,
        'timeInRange': timeInRange,
        'readingsCount': dayReadings.length,
        'lowCount': lowCount,
        'highCount': highCount,
        'calculatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('✅ Statistics updated for ${readingsByDate.length} days');
  }

  /// Get daily statistics for a date range
  Future<Map<String, Map<String, dynamic>>> getDailyStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('statistics')
        .doc('daily_stats')
        .collection('dates')
        .where('date', isGreaterThanOrEqualTo: _formatDateKey(startDate))
        .where('date', isLessThanOrEqualTo: _formatDateKey(endDate))
        .get();

    final Map<String, Map<String, dynamic>> stats = {};
    for (final doc in snapshot.docs) {
      stats[doc.id] = doc.data();
    }

    return stats;
  }

  // ========== USER PROFILE ==========

  /// Initialize user profile on first login
  Future<void> initializeUserProfile(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'settings': {
          'targetRange': {'low': 70, 'high': 180},
          'units': 'mg/dL',
        },
      });
      debugPrint('✅ User profile created for ${user.email}');
    } else {
      // Update last login
      await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      debugPrint('✅ Last login updated for ${user.email}');
    }
  }

  /// Check if user has any data in Firestore
  Future<bool> hasExistingData() async {
    if (_userId == null) return false;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('glucose_readings')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking existing data: $e');
      return false;
    }
  }

  // ========== DELETE OPERATIONS ==========

  /// Delete all user data (for testing/reset)
  Future<void> deleteAllUserData() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('⚠️ Deleting all user data...');

    final batch = _firestore.batch();

    // Delete glucose readings
    final readingsSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('glucose_readings')
        .get();

    for (final doc in readingsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete imports
    final importsSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('csv_imports')
        .get();

    for (final doc in importsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete statistics
    final statsSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('statistics')
        .doc('daily_stats')
        .collection('dates')
        .get();

    for (final doc in statsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    debugPrint('✅ All user data deleted');
  }

  // ========== HELPER METHODS ==========

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
