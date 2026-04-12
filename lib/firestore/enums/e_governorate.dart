enum EGovernorate {
  benArous, // 1
  ariana,   // 2
  mannouba, // 3
  tunis,    // 4
}

extension EGovernorateExtension on EGovernorate {
  // Conversion Enum -> String (Affichage UI propre)
  String get label {
    switch (this) {
      case EGovernorate.benArous:
        return "Ben Arous";
      case EGovernorate.ariana:
        return "Ariana";
      case EGovernorate.mannouba:
        return "Mannouba";
      case EGovernorate.tunis:
        return "Tunis";
    }
  }

  // Pour le stockage via ID numérique si besoin
  int get id {
    switch (this) {
      case EGovernorate.benArous:
        return 1;
      case EGovernorate.ariana:
        return 2;
      case EGovernorate.mannouba:
        return 3;
      case EGovernorate.tunis:
        return 4;
    }
  }

  // Conversion statique Int -> Enum (Utile pour la lecture DB)
  static EGovernorate fromInt(int id) {
    return EGovernorate.values.firstWhere(
          (e) => e.id == id,
      orElse: () => EGovernorate.tunis,
    );
  }

  // Conversion statique String (Name) -> Enum (Utile pour Firestore .name)
  static EGovernorate fromName(String name) {
    return EGovernorate.values.firstWhere(
          (e) => e.name == name,
      orElse: () => EGovernorate.tunis,
    );
  }
}