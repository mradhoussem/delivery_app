import 'package:flutter/material.dart';

BoxDecoration neumorphicDeco() {
  return BoxDecoration(
    color: const Color(0xFFF0F2F5),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        offset: const Offset(10, 10),
        blurRadius: 20,
      ),
      const BoxShadow(
        color: Colors.white,
        offset: Offset(-10, -10),
        blurRadius: 20,
      ),
    ],
  );
}