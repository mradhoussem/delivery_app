import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String phone1;
  final String phone2;
  final String role;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phone1,
    required this.phone2,
    required this.role,
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? phone1,
    String? phone2,
    String? role,
    DateTime? createdAt,
  }) => UserModel(
    id: id ?? this.id,
    username: username ?? this.username,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone1: phone1 ?? this.phone1,
    phone2: phone2 ?? this.phone2,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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