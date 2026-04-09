import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery_app/firestore/models/m_user.dart';

class UserDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Private helper to ensure hashing is identical for both adding and logging in
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Handles User Authentication
  /// UI sends raw password -> we hash it here -> we compare with DB
  Future<UserModel?> loginUser({
    required String username,
    required String password,
  }) async {
    final String hashedInput = _hashPassword(password);

    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: hashedInput)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromFirestore(query.docs.first);
    }
    return null;
  }

  /// Fetches all users for the Admin panel
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Adds a new user with automatic hashing
  /// UI sends raw password -> we hash it here -> we save to Firestore
  Future<void> addUser(UserModel user, String rawPassword) async {
    Map<String, dynamic> data = user.toMap();
    data['password'] = _hashPassword(rawPassword);
    await _db.collection('users').add(data);
  }

  /// Updates an existing user's password
  Future<void> updatePassword(String userId, String newRawPassword) async {
    final String hashedNewPassword = _hashPassword(newRawPassword);
    await _db.collection('users').doc(userId).update({
      'password': hashedNewPassword,
    });
  }

  /// Validates if a username is already taken
  Future<bool> checkUsernameExists(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return query.docs.isNotEmpty;
  }
}