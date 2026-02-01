import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Serwis dla administratora - zarządzanie użytkownikami i rolami
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Pobierz wszystkich użytkowników (stream)
  Stream<List<UserProfile>> getAllUsersStream({String? searchQuery}) {
    // Pobierz wszystkich użytkowników bez sortowania w query
    Query query = _firestore.collection('users');

    return query.snapshots().map((snapshot) {
      var users = snapshot.docs
          .map(
            (doc) =>
                UserProfile.fromFirestore(doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Sortuj lokalnie po email
      users.sort((a, b) => a.email.compareTo(b.email));

      // Filtruj po wyszukiwaniu lokalnie (email lub displayName)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return users.where((user) {
          return user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
              user.displayName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();
      }

      return users;
    });
  }

  /// Zmień rolę użytkownika
  Future<void> changeUserRole(String userId, UserRole newRole) async {
    if (_userId == null) {
      throw Exception('Admin not authenticated');
    }

    // Sprawdź czy ten użytkownik to admin
    final adminDoc = await _firestore.collection('users').doc(_userId).get();
    if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
      throw Exception('Only admins can change user roles');
    }

    // Zmień rolę
    await _firestore.collection('users').doc(userId).update({
      'role': newRole.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _userId,
    });

    debugPrint('✅ Changed role for user $userId to ${newRole.value}');
  }

  /// Pobierz statystyki użytkowników
  Future<Map<String, int>> getUserStatistics() async {
    final snapshot = await _firestore.collection('users').get();

    int patients = 0;
    int doctors = 0;
    int admins = 0;

    for (var doc in snapshot.docs) {
      final role = doc.data()['role'] as String?;
      switch (role) {
        case 'patient':
          patients++;
          break;
        case 'doctor':
          doctors++;
          break;
        case 'admin':
          admins++;
          break;
      }
    }

    return {
      'patients': patients,
      'doctors': doctors,
      'admins': admins,
      'total': snapshot.docs.length,
    };
  }

  /// Usuń użytkownika (opcjonalnie - use with caution!)
  Future<void> deleteUser(String userId) async {
    if (_userId == null) {
      throw Exception('Admin not authenticated');
    }

    // Sprawdź czy ten użytkownik to admin
    final adminDoc = await _firestore.collection('users').doc(_userId).get();
    if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
      throw Exception('Only admins can delete users');
    }

    // Nie można usunąć samego siebie
    if (userId == _userId) {
      throw Exception('Cannot delete your own account');
    }

    // Usuń dokument użytkownika
    await _firestore.collection('users').doc(userId).delete();

    debugPrint('✅ Deleted user $userId');
  }
}
