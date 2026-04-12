import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:flutter/foundation.dart';

class PackageDB {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'packages';

  CollectionReference<PackageModel> get _packageRef => _db
      .collection(_collection)
      .withConverter<PackageModel>(
    fromFirestore: (snapshot, _) => PackageModel.fromFirestore(snapshot),
    toFirestore: (package, _) => package.toMap(),
  );

  Future<QuerySnapshot<PackageModel>> getPackagesByUserPaged({
    required String userId,
    String? exactPhone,
    String? status, // Add this
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = true,
  }) async {
    try {
      Query<PackageModel> query = _packageRef.where('creatorUserId', isEqualTo: userId);

      // Filter by Status (if not "ALL")
      if (status != null && status != "ALL") {
        query = query.where('status', isEqualTo: status);
      }

      // Search Logic: phone1 OR phone2
      if (exactPhone != null && exactPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: exactPhone),
            Filter('phone2', isEqualTo: exactPhone),
          ),
        );
      }

      query = query.orderBy('createdAt', descending: descending).limit(limit);

      if (startAt != null) {
        query = query.startAtDocument(startAt);
      }

      return await query.get();
    } catch (e) {
      debugPrint("Firestore Error: $e");
      rethrow;
    }
  }

  Future<QuerySnapshot<PackageModel>> getAllPackagesPaged({
    String? exactPhone,
    String? status,
    DocumentSnapshot? startAt,
    int limit = 10,
    bool descending = true,
  }) async {
    try {
      Query<PackageModel> query = _packageRef;

      // Filter by Status (if not "ALL")
      if (status != null && status != "ALL") {
        query = query.where('status', isEqualTo: status);
      }

      // Search Logic: phone1 OR phone2
      if (exactPhone != null && exactPhone.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('phone1', isEqualTo: exactPhone),
            Filter('phone2', isEqualTo: exactPhone),
          ),
        );
      }

      // Sorting and Pagination
      query = query.orderBy('createdAt', descending: descending).limit(limit);

      if (startAt != null) {
        query = query.startAtDocument(startAt);
      }

      return await query.get();
    } catch (e) {
      debugPrint("Firestore Error: $e");
      rethrow;
    }
  }

  Future<void> addPackage(PackageModel package) async => await _packageRef.add(package);

  Future<void> updatePackageFields(String packageId, Map<String, dynamic> data) async {
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