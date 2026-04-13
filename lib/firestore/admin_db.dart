import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class AdminDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    final query = await _db
        .collection('admin_users')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: _hashPassword(password))
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}