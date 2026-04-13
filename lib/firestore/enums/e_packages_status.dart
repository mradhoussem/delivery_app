import 'package:flutter/material.dart';

enum EPackageStatus {
  waiting, // 1
  deposit, // 2
  returnFromDeposit, // 3
  progressing, // 4
  delivered, // 5
  payed, // 6
  permanentReturn, // 7
  returnReceived, // 8
}

extension EPackageStatusExtension on EPackageStatus {
  String get label {
    switch (this) {
      case EPackageStatus.waiting: return "En Attente";
      case EPackageStatus.deposit: return "Au Dépot";
      case EPackageStatus.returnFromDeposit: return "Retour Dépot";
      case EPackageStatus.progressing: return "En Cours";
      case EPackageStatus.delivered: return "Livrée";
      case EPackageStatus.payed: return "Livrée payée";
      case EPackageStatus.permanentReturn: return "Retour définitif";
      case EPackageStatus.returnReceived: return "Retour réçu";
    }
  }

  // Define the colors inside the enum extension
  List<Color> get gradientColors {
    switch (this) {
      case EPackageStatus.waiting:
      // Soft Slate: Neutral and calm
        return [const Color(0xFF607D8B), const Color(0xFF90A4AE)];
      case EPackageStatus.deposit:
      // Ocean Blue: Professional and stable
        return [const Color(0xFF1E88E5), const Color(0xFF64B5F6)];
      case EPackageStatus.returnFromDeposit:
      // Sunset Orange: Warning but not critical
        return [const Color(0xFFF4511E), const Color(0xFFFF8A65)];
      case EPackageStatus.progressing:
      // Electric Violet: Movement and energy
        return [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
      case EPackageStatus.delivered:
      // Fresh Leaf: Success and completion
        return [const Color(0xFF43A047), const Color(0xFF81C784)];
      case EPackageStatus.payed:
      // Royal Emerald: Financial completion / Premium
        return [const Color(0xFF00897B), const Color(0xFF4DB6AC)];
      case EPackageStatus.permanentReturn:
      // Deep Crimson: Finality / Action required
        return [const Color(0xFFE53935), const Color(0xFFEF5350)];
      case EPackageStatus.returnReceived:
      // Indigo: Back in inventory / Secure
        return [const Color(0xFF3949AB), const Color(0xFF7986CB)];
    }
  }

  int get id {
    switch (this) {
      case EPackageStatus.waiting: return 1;
      case EPackageStatus.deposit: return 2;
      case EPackageStatus.returnFromDeposit: return 3;
      case EPackageStatus.progressing: return 4;
      case EPackageStatus.delivered: return 5;
      case EPackageStatus.payed: return 6;
      case EPackageStatus.permanentReturn: return 7;
      case EPackageStatus.returnReceived: return 8;
    }
  }
}




