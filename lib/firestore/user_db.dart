import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery_app/firestore/models/m_user.dart';

class UserDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<UserModel?> loginUser({
    required String username,
    required String password,
  }) async {
    final String hashedInput = _hashPassword(password);
    // Convert to lowercase for case-insensitive login
    final String normalizedUsername = username.toLowerCase();

    final query = await _db
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .where('password', isEqualTo: hashedInput)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(
        query.docs.first.data(),
        id: query.docs.first.id,
      );
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }


  Future<void> addUser(UserModel user, String rawPassword) async {
    Map<String, dynamic> data = user.toMap();
    // Normalize username to lowercase before saving
    data['username'] = user.username.toLowerCase();
    data['password'] = _hashPassword(rawPassword);
    await _db.collection('users').add(data);
  }

  Future<void> updatePassword(String userId, String newRawPassword) async {
    final String hashedNewPassword = _hashPassword(newRawPassword);
    await _db.collection('users').doc(userId).update({
      'password': hashedNewPassword,
    });
  }

  Future<bool> checkUsernameExists(String username) async {
    // Convert to lowercase to check against stored lowercase usernames
    final String normalizedUsername = username.toLowerCase();
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .get();
    return query.docs.isNotEmpty;
  }
}