import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/tools/images_files.dart';

class LoadingOverlay {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User can't click away
      builder: (context) => const _PulseLoader(),
    );
  }

  static void hide(BuildContext context) {
    Navigator.pop(context);
  }
}

class _PulseLoader extends StatefulWidget {
  const _PulseLoader();

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DefaultColors.background.withValues(alpha: 0.7),
        body: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              ImagesFiles.logo2,
              width: 100,
            ),
          ),
        ),
      ),
    );
  }
}