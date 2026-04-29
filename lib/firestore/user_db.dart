import 'dart:convert';
import 'package:delivery_app/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery_app/firestore/models/m_user.dart';

class UserDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Gère l'affichage d'une alerte si le quota Firestore est épuisé
  void _handleFirestoreError(Object e) {
    if (e is FirebaseException && e.code == 'resource-exhausted') {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Limite atteinte'),
            content: const Text(
                'La limite quotidienne gratuite de la base de données a été atteinte. '
                    'L’application sera de nouveau opérationnelle demain.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<UserModel?> loginUser({
    required String username,
    required String password,
  }) async {
    try {
      final String hashedInput = _hashPassword(password);
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
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<void> addUser(UserModel user, String rawPassword) async {
    try {
      Map<String, dynamic> data = user.toMap();
      data['username'] = user.username.toLowerCase();
      data['password'] = _hashPassword(rawPassword);
      await _db.collection('users').add(data);
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<void> updatePassword(String userId, String newRawPassword) async {
    try {
      final String hashedNewPassword = _hashPassword(newRawPassword);
      await _db.collection('users').doc(userId).update({
        'password': hashedNewPassword,
      });
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final String normalizedUsername = username.toLowerCase();
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }
}