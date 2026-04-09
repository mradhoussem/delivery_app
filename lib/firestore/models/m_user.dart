import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String firstName; // Nouveau champ
  final String lastName;  // Nouveau champ
  final String phone1;
  final String phone2;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phone1,
    required this.phone2,
    required this.role,
    this.createdAt,
  });

  // Convert Firestore Document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? 'Inconnu',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone1: data['phone1'] ?? '',
      phone2: data['phone2'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert UserModel to Map for Saving
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phone1': phone1,
      'phone2': phone2,
      'role': role,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}