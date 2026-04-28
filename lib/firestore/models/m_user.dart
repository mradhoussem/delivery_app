import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? email; // Added optional email
  final String phone1;
  final String phone2;
  final String role;
  final double deliveryCosts;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email, // Optional
    required this.phone1,
    required this.phone2,
    required this.role,
    required this.deliveryCosts,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? phone1,
    String? phone2,
    String? role,
    double? deliveryCosts,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      role: role ?? this.role,
      deliveryCosts: deliveryCosts ?? this.deliveryCosts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      id: id ?? data['id'] ?? '',
      username: data['username'] ?? 'Inconnu',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'],
      // Fetch from map
      phone1: data['phone1'] ?? '',
      phone2: data['phone2'] ?? '',
      role: data['role'] ?? 'user',
      deliveryCosts: (data['deliveryCosts'] ?? 0.0).toDouble(),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email, // Add to map
      'phone1': phone1,
      'phone2': phone2,
      'role': role,
      'deliveryCosts': deliveryCosts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}