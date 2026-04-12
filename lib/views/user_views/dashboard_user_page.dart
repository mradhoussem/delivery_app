import 'package:delivery_app/views/user_views/add_package_page.dart';
import 'package:delivery_app/views/user_views/packages_stats_page.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/tools/default_colors.dart';

class DashboardUserPage extends StatelessWidget {
  final String username;

  const DashboardUserPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 30),
          _actionCard(context),
          const SizedBox(height: 40),
          const SizedBox(height: 15),
          PackagesStatsPage(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Sous-composants conservés en méthodes privées car ils sont spécifiques à cette page ---

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bonjour, $username",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Que souhaitez-vous faire aujourd'hui ?",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: DefaultColors.primary.withValues(alpha: 0.1),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_rounded,
            size: 40,
            color: DefaultColors.primary,
          ),
          const SizedBox(height: 15),
          const Text(
            "Nouvelle Expédition",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Envoyez vos colis en quelques clics.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _actionButton(context),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPackagePage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: DefaultColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: const Text("COMMENCER"),
    );
  }
}
