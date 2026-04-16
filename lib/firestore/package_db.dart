import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
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

  Future<QuerySnapshot<PackageModel>> getPackagesByUserPaged({
    required String userId,
    String? exactPhone,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = false,
  }) async {
    debugPrint("getPackagesByUserPaged");
    try {
      Query<PackageModel> query = _packageRef.where(
        'creatorUserId',
        isEqualTo: userId,
      );

      if (exactPhone != null && exactPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: exactPhone),
            Filter('phone2', isEqualTo: exactPhone),
          ),
        );
      }

      // FIX: Use descending directly. Newest (desc) should be true by default.
      query = query.orderBy('createdAt', descending: descending);

      if (startAt != null) {
        query = query.startAfterDocument(startAt);
      }

      return await query.limit(limit).get();
    } catch (e) {
      debugPrint("Firestore Database Error: $e");
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getPackagesByUserByStatusPaged({
    required String userId,
    required String status,
    String? exactPhone,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = true,
  }) async {
    debugPrint("getPackagesByUserByStatusPaged");
    try {
      Query<PackageModel> query = _packageRef.where(
        'creatorUserId',
        isEqualTo: userId,
      );

      query = query.where('status', isEqualTo: status);

      if (exactPhone != null && exactPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: exactPhone),
            Filter('phone2', isEqualTo: exactPhone),
          ),
        );
      }

      // FIX: Use descending directly.
      query = query.orderBy('createdAt', descending: descending);

      if (startAt != null) {
        query = query.startAfterDocument(startAt);
      }

      return await query.limit(limit).get();
    } catch (e) {
      debugPrint("Firestore Database Error: $e");
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getAdminPackagesPaged({
    String? searchUsername,
    String? searchPhone,
    DocumentSnapshot? startAt,
    int limit = 50,
    required bool descending,
  }) async {
    try {
      Query<PackageModel> query = _packageRef;

      // 1. Filter by Phone (Exact) if provided
      if (searchPhone != null && searchPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: searchPhone),
            Filter('phone2', isEqualTo: searchPhone),
          ),
        );
      }

      // 2. Filter by Username (Prefix) if provided
      // Chaining this with the phone filter above
      if (searchUsername != null && searchUsername.isNotEmpty) {
        query = query
            .where('creatorUsername', isGreaterThanOrEqualTo: searchUsername)
            .where('creatorUsername', isLessThanOrEqualTo: '$searchUsername\uf8ff');
      }

      // 3. Apply Sorting
      // Note: If you search by username prefix, Firestore requires
      // the first orderBy to be the same field (creatorUsername).
      if (searchUsername != null && searchUsername.isNotEmpty) {
        query = query.orderBy('creatorUsername');
      }

      query = query.orderBy('createdAt', descending: descending);

      if (startAt != null) {
        query = query.startAfterDocument(startAt);
      }

      return await query.limit(limit).get();
    } catch (e) {
      debugPrint("Admin Global Fetch Error: $e");
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getAllPackagesPaged({
    String? exactPhone,
    String? status,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = false,
  }) async {
    debugPrint("getAllPackagesPaged");
    try {
      Query<PackageModel> query = _packageRef;

      if (status != null && status != "ALL") {
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

      // FIX: Use descending directly and use startAfterDocument
      query = query.orderBy('createdAt', descending: descending);

      if (startAt != null) {
        query = query.startAfterDocument(startAt);
      }

      return await query.limit(limit).get();
    } catch (e) {
      debugPrint("Firestore Error: $e");
      rethrow;
    }
  }

  Future<List<PackageModel>> getAllPackagesByStatus({
    required String userId,
    required String status,
    bool descending = false,
  }) async {
    debugPrint("getAllPackagesByStatus");
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('creatorUserId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: descending) // FIX: Use descending directly
          .get();

      return snapshot.docs
          .map((doc) => PackageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("getAllPackagesByStatus ERROR: $e");
      return [];
    }
  }

  Future<int> getPackageCountByStatus({
    required String userId,
    String? status,
  }) async {
    debugPrint("getPackageCountByStatus");
    try {
      Query<PackageModel> query = _packageRef.where(
        'creatorUserId',
        isEqualTo: userId,
      );

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final aggregateQuery = query.count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint("Firestore Count Error: $e");
      return 0;
    }
  }

  Future<DocumentReference> addPackage(PackageModel package) =>
      _packageRef.add(package);

  Future<void> updatePackageFields(
      String packageId,
      Map<String, dynamic> data,
      ) async {
    await _db.collection(_collection).doc(packageId).update(data);
  }

  Future<void> deletePackage(String packageId) async {
    await _db.collection(_collection).doc(packageId).delete();
  }

  Future<PackageModel?> getPackageById(String packageId) async {
    final doc = await _packageRef.doc(packageId).get();
    return doc.data();
  }
}