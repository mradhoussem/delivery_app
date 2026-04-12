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
  // Conversion Enum -> String (Affichage UI)
  String get label {
    switch (this) {
      case EPackageStatus.waiting:
        return "En Attente";
      case EPackageStatus.deposit:
        return "Au Dépot";
      case EPackageStatus.returnFromDeposit:
        return "Retour Dépot";
      case EPackageStatus.progressing:
        return "En Cours";
      case EPackageStatus.delivered:
        return "Livrée";
      case EPackageStatus.payed:
        return "Livrée payée";
      case EPackageStatus.permanentReturn:
        return "Retour définitif";
      case EPackageStatus.returnReceived:
        return "Retour réçu";
    }
  }

  // Pour stocker l'ID numérique si nécessaire
  int get id {
    switch (this) {
      case EPackageStatus.waiting:
        return 1;
      case EPackageStatus.deposit:
        return 2;
      case EPackageStatus.returnFromDeposit:
        return 3;
      case EPackageStatus.progressing:
        return 4;
      case EPackageStatus.delivered:
        return 5;
      case EPackageStatus.payed:
        return 6;
      case EPackageStatus.permanentReturn:
        return 7;
      case EPackageStatus.returnReceived:
        return 8;
    }
  }

  // Conversion statique Int -> Enum
  static EPackageStatus fromInt(int id) {
    return EPackageStatus.values.firstWhere(
      (e) => e.id == id,
      orElse: () => EPackageStatus.waiting,
    );
  }
}
