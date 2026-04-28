import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:flutter/foundation.dart';

class PackageDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'packages';

  CollectionReference<PackageModel> get _packageRef => _db
      .collection(_collection)
      .withConverter<PackageModel>(
        fromFirestore: (snapshot, _) =>
            PackageModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (package, _) => package.toMap(),
      );

  /// ✅ NEW: Automatically fetches the user's specific delivery cost and saves the package
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
      debugPrint("AutoCost Save Error: $e");
      rethrow;
    }
  }

  // --- Existing Methods (RESTORED) ---

  Future<QuerySnapshot<PackageModel>> getPackagesByUserPaged({
    required String userId,
    String? exactPhone,
    String? status, // Assure-toi que ce paramètre est bien là
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = false,
  }) async {
    try {
      Query<PackageModel> query = _packageRef.where(
        'creatorUserId',
        isEqualTo: userId,
      );

      // AJOUTE CETTE CONDITION :
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
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getPackagesByUserByStatusPaged({
    required String userId,
    required List<EPackageStatus> statuses, // Changé de EPackageStatus à List
    String? exactPhone,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = true,
  }) async {
    try {
      // Conversion de la liste d'enums en liste de Strings pour Firestore
      List<String> statusNames = statuses.map((e) => e.name).toList();

      Query<PackageModel> query = _packageRef
          .where('creatorUserId', isEqualTo: userId)
          .where('status', whereIn: statusNames); // Utilisation de whereIn

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
      return 0;
    }
  }


  Future<QuerySnapshot<PackageModel>> getAdminPackagesPaged({
    EPackageStatus? status, // Nouveau paramètre
    String? searchUsername,
    String? searchPhone,
    DocumentSnapshot? startAt,
    int limit = 50,
    required bool descending,
  }) async {
    try {
      Query<PackageModel> query = _packageRef;

      // 1. Filtre d'égalité pour le statut (toujours en premier)
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      // 2. Filtre de recherche par téléphone (Filtre OR)
      if (searchPhone != null && searchPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: searchPhone),
            Filter('phone2', isEqualTo: searchPhone),
          ),
        );
      }

      // 3. Filtre de recherche par nom (Filtre d'inégalité)
      if (searchUsername != null && searchUsername.isNotEmpty) {
        query = query
            .where('creatorUsername', isGreaterThanOrEqualTo: searchUsername)
            .where(
          'creatorUsername',
          isLessThanOrEqualTo: '$searchUsername\uf8ff',
        )
            .orderBy('creatorUsername'); // Doit être le premier orderBy si filtré
      }

      // 4. Tri par date de création
      query = query.orderBy('createdAt', descending: descending);

      // 5. Pagination
      if (startAt != null) query = query.startAfterDocument(startAt);

      return await query.limit(limit).get();
    } catch (e) {
      debugPrint("Erreur Firestore: $e");
      rethrow;
    }
  }

  Future<List<PackageModel>> getUserPaidPackagesForReport({
    required String userId,
    required int year,
    required int month,
  }) async {
    final snapshot = await _packageRef
        .where('creatorId', isEqualTo: userId)
        .where('status', isEqualTo: EPackageStatus.payed.name)
    // Vous devrez peut-être filtrer sur un champ 'paymentDate' ou 'createdAt'
    // selon votre structure Firestore
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

// Récupérer les colis par statut pour un utilisateur spécifique
  Future<List<PackageModel>> getUserPackagesByStatus({
    required String userId,
    required EPackageStatus status,
  }) async {
    final snapshot = await _packageRef
        .where('creatorId', isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
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
          .map((doc) =>
          PackageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching packages by status: $e");
      return [];
    }
  }

  Future<List<PackageModel>> getPaidPackagesForReport({
    required int year,
    required int month,
  }) async {
    try {
      // 1. Define the start of the month (e.g., 2026-04-01 00:00:00)
      final DateTime startOfMonth = DateTime(year, month, 1);

      // 2. Define the end of the month (e.g., 2026-05-01 00:00:00, then subtract 1 ms)
      // Or more simply: DateTime(year, month + 1, 0, 23, 59, 59)
      final DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      // 3. Query Firestore with range filters
      final snapshot = await _db
          .collection(_collection)
          .where('status', isEqualTo: EPackageStatus.payed.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: true)
          .get();

      // 4. Map the documents to your PackageModel
      return snapshot.docs.map((doc) {
        return PackageModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching paid packages for report: $e");
      return [];
    }
  }


  Future<void> updatePackageFields(
    String packageId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(_collection).doc(packageId).update(data);
  }

  Future<void> updateStatus(String packageId, EPackageStatus newStatus) async {
    try {
      await _db.collection(_collection).doc(packageId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating status: $e");
      rethrow;
    }
  }

  Future<void> deletePackage(String packageId) async {
    await _db.collection(_collection).doc(packageId).delete();
  }

  Future<PackageModel?> getPackageById(String packageId) async {
    final doc = await _packageRef.doc(packageId).get();
    return doc.data();
  }

  /// ✅ NEW: Fetches paid packages filtered by year and month strings
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
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .orderBy('createdAt', descending: descending);

      if (startAt != null) query = query.startAfterDocument(startAt);
      return await query.limit(limit).get();
    } catch (e) {
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
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
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
      rethrow;
    }
  }

  int _getMonthNumber(String monthName) {
    final months = [
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ];
    return months.indexOf(monthName) + 1;
  }
}
