import 'package:cloud_firestore/cloud_firestore.dart';

/// Model profilu użytkownika z rolą (patient, doctor, admin)
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
    this.lastLogin,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      role: UserRole.fromString(data['role'] ?? 'patient'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.value,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    };
  }

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;
  bool get isAdmin => role == UserRole.admin;

  // Helper do wyświetlania roli po polsku
  String get roleDisplayName {
    switch (role) {
      case UserRole.patient:
        return 'Pacjent';
      case UserRole.doctor:
        return 'Lekarz';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

enum UserRole {
  patient('patient'),
  doctor('doctor'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.patient,
    );
  }
}
