import 'package:flutter/material.dart';

class RwAppbar extends StatelessWidget {
  final String username;
  final VoidCallback onMenuPressed;
  final Color primaryColor;
  final Color iconColor;

  const RwAppbar({
    super.key,
    required this.username,
    required this.onMenuPressed,
    required this.primaryColor,
    this.iconColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    // Détection interne
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // On peut changer l'icône selon le contexte si besoin
          IconButton(
            icon: Icon(
                isWide ? Icons.menu_open : Icons.menu,
                color: primaryColor,
                size: 30
            ),
            onPressed: onMenuPressed,
          ),
          const Spacer(),
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: primaryColor,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : "?",
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}