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
  final double deliveryCost;
  final bool isExchange;
  final String? productDesignation;
  final String? packageDesignation;
  final String? comment;
  final EPackageStatus status;
  final DateTime createdAt;
  final String creatorUserId;
  final String creatorUsername;
  final String creatorTaxId; // <--- NEW FIELD

  const PackageModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone1,
    this.phone2,
    required this.governorate,
    required this.address,
    required this.amount,
    required this.deliveryCost,
    this.isExchange = false,
    this.productDesignation,
    this.packageDesignation,
    this.comment,
    this.status = EPackageStatus.waiting,
    required this.creatorUserId,
    required this.creatorUsername,
    required this.creatorTaxId, // <--- NEW FIELD
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
    double? deliveryCost,
    bool? isExchange,
    String? productDesignation,
    String? packageDesignation,
    String? comment,
    EPackageStatus? status,
    DateTime? createdAt,
    String? creatorUserId,
    String? creatorUsername,
    String? creatorTaxId, // <--- NEW FIELD
  }) {
    return PackageModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      governorate: governorate ?? this.governorate,
      address: address ?? this.address,
      amount: amount ?? this.amount,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      isExchange: isExchange ?? this.isExchange,
      productDesignation: productDesignation ?? this.productDesignation,
      packageDesignation: packageDesignation ?? this.packageDesignation,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorTaxId: creatorTaxId ?? this.creatorTaxId, // <--- NEW FIELD
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone1': phone1,
      'phone2': phone2,
      'governorate': governorate.name,
      'address': address,
      'amount': amount,
      'deliveryCost': deliveryCost,
      'isExchange': isExchange,
      'productDesignation': productDesignation,
      'packageDesignation': packageDesignation,
      'comment': comment,
      'status': status.name,
      'creatorUserId': creatorUserId,
      'creatorUsername': creatorUsername,
      'creatorTaxId': creatorTaxId, // <--- NEW FIELD
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PackageModel.fromMap(Map<String, dynamic> data, String id) {
    return PackageModel(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone1: data['phone1'] ?? '',
      phone2: data['phone2'],
      governorate: EGovernorateExtension.fromName(data['governorate'] ?? ''),
      address: data['address'] ?? '',
      amount: _parseDouble(data['amount']),
      deliveryCost: _parseDouble(data['deliveryCost']),
      isExchange: data['isExchange'] ?? false,
      productDesignation: data['productDesignation'],
      packageDesignation: data['packageDesignation'],
      comment: data['comment'],
      status: EPackageStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => EPackageStatus.waiting,
      ),
      creatorUserId: data['creatorUserId'] ?? '',
      creatorUsername: data['creatorUsername'] ?? '',
      creatorTaxId: data['creatorTaxId'] ?? '', // <--- NEW FIELD
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}