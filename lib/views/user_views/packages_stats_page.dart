import 'package:flutter/material.dart';
import 'package:delivery_app/reusable_widgets/rw_flip_card.dart';

class PackagesStatsPage extends StatelessWidget {
  const PackagesStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Liste des données pour les statistiques
    final List<Map<String, dynamic>> cardData = [
      {
        "title": "Total Expéditions",
        "val": "1,284",
        "colors": [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
      },
      {
        "title": "En attente",
        "val": "12",
        "colors": [const Color(0xFF8e2de2), const Color(0xFF4a00e0)],
      },
      {
        "title": "Livrées",
        "val": "1,272",
        "colors": [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      },
      {
        "title": "Annulées",
        "val": "05",
        "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)],
      },
      {
        "title": "En retard",
        "val": "02",
        "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistiques Détaillées",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Suivi en temps réel de vos activités d'expédition.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),

        // La grille de cartes
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: cardData
              .map(
                (data) => RwFlipCard(
                  title: data["title"],
                  value: data["val"],
                  gradientColors: data["colors"],
                  onTap: () {
                    // Action possible : naviguer vers une liste filtrée
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
