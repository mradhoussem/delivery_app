import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/material.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _pulseCount = 0;

  @override
  void initState() {
    super.initState();

    // 1. Setup the animation (800ms for a snappier pulse)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 2. Logic to handle the pulses and navigation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseCount++;
        if (_pulseCount < 2) {
          _controller.forward();
        } else {
          // --- NAVIGATION ---
          // Use pushReplacementNamed to match your main.dart routes
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    });

    // Start the first pulse
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using withOpacity for broader Flutter version support
      backgroundColor: DefaultColors.background.withValues(alpha: 0.7),
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Image.asset(
            ImagesFiles.logo2,
            width: 100, // Slightly larger for the splash screen
          ),
        ),
      ),
    );
  }
}