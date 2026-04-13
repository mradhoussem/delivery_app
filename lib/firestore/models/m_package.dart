import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/enums/e_governorate.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';

class PackageModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone1;
  final String? phone2;
  final EGovernorate governorate;
  final String address;
  final double amount;
  final bool isExchange;
  final String? packageDesignation;
  final String? comment;
  final EPackageStatus status;
  final DateTime createdAt;
  final String creatorUserId;
  final String creatorUsername;

  const PackageModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone1,
    this.phone2,
    required this.governorate,
    required this.address,
    required this.amount,
    this.isExchange = false,
    this.packageDesignation,
    this.comment,
    this.status = EPackageStatus.waiting,
    required this.creatorUserId,
    required this.creatorUsername,
    required this.createdAt,
  });

  PackageModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone1,
    String? phone2,
    EGovernorate? governorate,
    String? address,
    double? amount,
    bool? isExchange,
    String? packageDesignation,
    String? comment,
    EPackageStatus? status,
    DateTime? createdAt,
    String? creatorUserId,
    String? creatorUsername,
  }) => PackageModel(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone1: phone1 ?? this.phone1,
    phone2: phone2 ?? this.phone2,
    governorate: governorate ?? this.governorate,
    address: address ?? this.address,
    amount: amount ?? this.amount,
    isExchange: isExchange ?? this.isExchange,
    packageDesignation: packageDesignation ?? this.packageDesignation,
    comment: comment ?? this.comment,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    creatorUserId: creatorUserId ?? this.creatorUserId,
    creatorUsername: creatorUsername ?? this.creatorUsername,
  );

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone1': phone1,
      'phone2': phone2,
      'governorate': governorate.name,
      'address': address,
      'amount': amount,
      'isExchange': isExchange,
      'packageDesignation': packageDesignation,
      'comment': comment,
      'status': status.name,
      'creatorUserId': creatorUserId,
      'creatorUsername': creatorUsername,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone1: data['phone1'] ?? '',
      phone2: data['phone2'],
      governorate: EGovernorateExtension.fromName(data['governorate'] ?? ''),
      address: data['address'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      isExchange: data['isExchange'] ?? false,
      packageDesignation: data['packageDesignation'],
      comment: data['comment'],
      status: EPackageStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => EPackageStatus.waiting,
      ),
      creatorUserId: data['creatorUserId'] ?? '',
      creatorUsername: data['creatorUsername'] ?? '',
      createdAt: DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}