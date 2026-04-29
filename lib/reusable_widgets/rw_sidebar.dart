import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/material.dart';

class RwSideBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  final Color primaryColor;
  final Color backgroundColor;
  final Color unselectedColor;

  final String portalTitle;

  final List<RwSideBarItem> items;

  const RwSideBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.primaryColor,
    required this.backgroundColor,
    required this.items,
    this.unselectedColor = Colors.grey,
    this.portalTitle = "PORTAIL EXPÉDITEUR",
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

          const SizedBox(height: 20),

          Image.asset(
            ImagesFiles.logo2,
            width: 120, // Slightly larger for the splash screen
          ),
          const SizedBox(height: 20),

          _buildNavItems(context),

          const Spacer(),

          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isSelected = selectedIndex == index;

        return _SidebarItem(
          title: item.title,
          icon: item.icon,
          isSelected: isSelected,
          primaryColor: primaryColor,
          unselectedColor: unselectedColor,
          onTap: () {
            onItemSelected(index);

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
      leading: Icon(
        Icons.logout,
        color: primaryColor.withValues(alpha: 0.7),
      ),
      title: Text(
        "Déconnexion",
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
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
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 15,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : unselectedColor,
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? primaryColor : unselectedColor,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
