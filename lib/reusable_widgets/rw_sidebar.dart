import 'package:flutter/material.dart';

class RwSideBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final Color primaryColor;
  final Color backgroundColor;
  final Color unselectedColor;
  final String
  portalTitle; // Paramètre pour changer "USER PORTAL" en "ADMIN PORTAL"

  const RwSideBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.primaryColor,
    required this.backgroundColor,
    this.unselectedColor = Colors.grey,
    this.portalTitle = "USER PORTAL",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: backgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            portalTitle,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          _buildNavItems(context),
          const Spacer(),
          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {"title": "Accueil", "icon": Icons.dashboard_rounded},
      {"title": "Mes Colis", "icon": Icons.inventory_2_rounded},
      {"title": "Paramètres", "icon": Icons.settings_rounded},
    ];

    return Column(
      children: List.generate(items.length, (index) {
        final bool isSelected = selectedIndex == index;
        return _SidebarItem(
          title: items[index]["title"],
          icon: items[index]["icon"],
          isSelected: isSelected,
          primaryColor: primaryColor,
          unselectedColor: unselectedColor,
          onTap: () {
            onItemSelected(index);
            // Ferme le drawer automatiquement si on est sur mobile
            if (MediaQuery.of(context).size.width <= 900) {
              Navigator.pop(context);
            }
          },
        );
      }),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
      leading: Icon(Icons.logout, color: primaryColor.withValues(alpha: 0.7)),
      title: Text(
        "Déconnexion",
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      ),
      onTap: onLogout,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color primaryColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.primaryColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? primaryColor : unselectedColor),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? primaryColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
