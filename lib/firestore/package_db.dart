import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/main.dart'; // Assure-toi que navigatorKey est ici
import 'package:flutter/material.dart';

class PackageDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'packages';

  /// Gestionnaire d'erreurs centralisé pour les quotas Firestore
  void _handleFirestoreError(Object e) {
    if (e is FirebaseException && e.code == 'resource-exhausted') {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              AlertDialog(
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

  CollectionReference<PackageModel> get _packageRef => _db
      .collection(_collection)
      .withConverter<PackageModel>(
    fromFirestore: (snapshot, _) =>
        PackageModel.fromMap(snapshot.data()!, snapshot.id),
    toFirestore: (package, _) => package.toMap(),
  );

  Future<DocumentReference> addPackage({
    required PackageModel package,
    required String userId,
  }) async {
    try {
      DocumentSnapshot userDoc = await _db
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("Configuration utilisateur introuvable.");
      }

      final user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        id: userDoc.id,
      );

      final finalPackage = package.copyWith(
        deliveryCost: user.deliveryCosts,
        createdAt: DateTime.now(),
      );

      return await _packageRef.add(finalPackage);
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getPackagesByUserPaged({
    required String userId,
    String? exactPhone,
    String? status,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = false,
  }) async {
    try {
      Query<PackageModel> query = _packageRef.where(
        'creatorUserId',
        isEqualTo: userId,
      );

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      if (exactPhone != null && exactPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: exactPhone),
            Filter('phone2', isEqualTo: exactPhone),
          ),
        );
      }

      query = query.orderBy('createdAt', descending: descending);
      if (startAt != null) query = query.startAfterDocument(startAt);
      return await query.limit(limit).get();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getPackagesByUserByStatusPaged({
    required String userId,
    required List<EPackageStatus> statuses,
    String? exactPhone,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = true,
  }) async {
    try {
      List<String> statusNames = statuses.map((e) => e.name).toList();

      Query<PackageModel> query = _packageRef
          .where('creatorUserId', isEqualTo: userId)
          .where('status', whereIn: statusNames);

      if (exactPhone != null && exactPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: exactPhone),
            Filter('phone2', isEqualTo: exactPhone),
          ),
        );
      }
      query = query.orderBy('createdAt', descending: descending);
      if (startAt != null) query = query.startAfterDocument(startAt);
      return await query.limit(limit).get();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<List<PackageModel>> getAllPackagesByStatus({
    required String userId,
    required EPackageStatus status,
    bool descending = false,
  }) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('creatorUserId', isEqualTo: userId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: descending)
          .get();
      return snapshot.docs
          .map((doc) => PackageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _handleFirestoreError(e);
      return [];
    }
  }

  Future<int> getPackageCountByStatus({
    required String userId,
    String? status,
  }) async {
    try {
      Query<PackageModel> query = _packageRef.where(
        'creatorUserId',
        isEqualTo: userId,
      );
      if (status != null) query = query.where('status', isEqualTo: status);
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      _handleFirestoreError(e);
      return 0;
    }
  }

  Future<QuerySnapshot<PackageModel>> getAdminPackagesPaged({
    EPackageStatus? status,
    String? searchUsername,
    String? searchPhone,
    DocumentSnapshot? startAt,
    int limit = 50,
    required bool descending,
  }) async {
    try {
      Query<PackageModel> query = _packageRef;

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (searchPhone != null && searchPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: searchPhone),
            Filter('phone2', isEqualTo: searchPhone),
          ),
        );
      }

      if (searchUsername != null && searchUsername.isNotEmpty) {
        query = query
            .where('creatorUsername', isGreaterThanOrEqualTo: searchUsername)
            .where(
          'creatorUsername',
          isLessThanOrEqualTo: '$searchUsername\uf8ff',
        )
            .orderBy('creatorUsername');
      }

      query = query.orderBy('createdAt', descending: descending);
      if (startAt != null) query = query.startAfterDocument(startAt);

      return await query.limit(limit).get();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<List<PackageModel>> getUserPaidPackagesForReport({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final snapshot = await _packageRef
          .where('creatorId', isEqualTo: userId)
          .where('status', isEqualTo: EPackageStatus.payed.name)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<List<PackageModel>> getAdminPackagesByStatus({
    required EPackageStatus status,
  }) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PackageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _handleFirestoreError(e);
      return [];
    }
  }

  Future<List<PackageModel>> getPaidPackagesForReport({
    required int year,
    required int month,
  }) async {
    try {
      final DateTime startOfMonth = DateTime(year, month, 1);
      final DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      final snapshot = await _db
          .collection(_collection)
          .where('status', isEqualTo: EPackageStatus.payed.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) =>
          PackageModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      _handleFirestoreError(e);
      return [];
    }
  }

  Future<void> updatePackageFields(String packageId,
      Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(packageId).update(data);
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<void> updateStatus(String packageId, EPackageStatus newStatus) async {
    try {
      await _db.collection(_collection).doc(packageId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<void> deletePackage(String packageId) async {
    try {
      await _db.collection(_collection).doc(packageId).delete();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<PackageModel?> getPackageById(String packageId) async {
    try {
      final doc = await _packageRef.doc(packageId).get();
      return doc.data();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getPaidPackagesByDatePaged({
    required String userId,
    required String yearStr,
    required String monthStr,
    DocumentSnapshot? startAt,
    int limit = 11,
    bool descending = true,
  }) async {
    try {
      int year = int.parse(yearStr);
      int month = _getMonthNumber(monthStr);

      final DateTime startOfMonth = DateTime(year, month, 1);
      final DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      Query<PackageModel> query = _packageRef
          .where('creatorUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'payed')
          .where(
          'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where(
          'createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: descending);

      if (startAt != null) query = query.startAfterDocument(startAt);
      return await query.limit(limit).get();
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  Future<Map<String, double>> getPaidTotalsByMonth({
    required String userId,
    required String yearStr,
    required String monthStr,
  }) async {
    try {
      int year = int.parse(yearStr);
      int month = _getMonthNumber(monthStr);

      final DateTime startOfMonth = DateTime(year, month, 1);
      final DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final snapshot = await _packageRef
          .where('creatorUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'payed')
          .where(
          'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where(
          'createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double totalAmount = 0;
      double totalDelivery = 0;
      int count = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalAmount += data.amount;
        totalDelivery += data.deliveryCost;
      }

      return {
        'count': count.toDouble(),
        'totalAmount': totalAmount,
        'totalDelivery': totalDelivery,
        'net': totalAmount - totalDelivery,
      };
    } catch (e) {
      _handleFirestoreError(e);
      rethrow;
    }
  }

  int _getMonthNumber(String monthName) {
    final months = [
      "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
    ];
    return months.indexOf(monthName) + 1;
  }
}