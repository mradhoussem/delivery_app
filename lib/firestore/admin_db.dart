import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/main.dart';

class AdminDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Gestionnaire d'erreurs centralisé pour les quotas Firestore
  void _handleFirestoreError(Object e) {
    if (e is FirebaseException && e.code == 'resource-exhausted') {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Limite du système atteinte'),
            content: const Text(
                'La base de données a atteint sa limite quotidienne gratuite. '
                    'L’accès sera rétabli automatiquement à minuit (heure Pacifique).'
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

  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final String normalizedEmail = email.toLowerCase();

      final query = await _db
          .collection('admin_users')
          .where('email', isEqualTo: normalizedEmail)
          .where('password', isEqualTo: _hashPassword(password))
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }
}