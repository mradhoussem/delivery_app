import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:delivery_app/views/user_views/add_package_page.dart';
import 'package:delivery_app/views/user_views/packages_stats_page.dart';
import 'package:flutter/material.dart';

class DashboardUserPage extends StatelessWidget {
  final String userId;
  final String username;
  final Function(int, {String? status}) onNavigate;

  const DashboardUserPage({
    super.key,
    required this.userId,
    required this.username,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "Bonjour, $username",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Que souhaitez-vous faire aujourd'hui ?",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _buildActionCard(context),
          const SizedBox(height: 40),
          PackagesStatsPage(
            userId: userId,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            children: [
              if (!isMobile)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Image.asset(
                    ImagesFiles.backgroundCar2,
                    width: 200,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nouvelle Expédition",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Créez un bordereau en quelques secondes",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPackagePage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DefaultColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("COMMENCER"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}