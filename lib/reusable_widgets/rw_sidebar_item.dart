import 'package:flutter/material.dart';

class RwSideBarItem {
  final String title;
  final IconData icon;
  final Widget? page; // Rendu optionnel
  final VoidCallback? onTap; // Ajout de l'action personnalisée

  const RwSideBarItem({
    required this.title,
    required this.icon,
    this.page,
    this.onTap,
  });
}