import 'package:flutter/material.dart';

class RwSideBarItem {
  final String title;
  final IconData icon;
  final Widget page;

  const RwSideBarItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}
