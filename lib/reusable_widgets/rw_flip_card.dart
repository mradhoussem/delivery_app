import 'package:flutter/material.dart';
import 'dart:math' as math;

class RwFlipCard extends StatefulWidget {
  final String title;
  final String value;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const RwFlipCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<RwFlipCard> createState() => _RwFlipCardState();
}

class _RwFlipCardState extends State<RwFlipCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    double cardWidth = isMobile ? 140 : 180;
    double cardHeight = isMobile ? 90 : 100;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 500),
          tween: Tween<double>(begin: 0, end: _isHovered ? math.pi : 0),
          builder: (context, double value, child) {
            final isFront = value <= math.pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(value),
              child: isFront
                  ? _buildFront(cardWidth, cardHeight, isMobile)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildBack(cardWidth, cardHeight),
                    ),
            );
          },
        ),
      ),
    );
  }

  // --- FRONT ---
  Widget _buildFront(double width, double height, bool isMobile) {
    return Container(
      width: width,
      height: height,
      decoration: _cardDecoration(widget.gradientColors),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            _buildCircle(-20, -20, 40, 0.15),
            _buildCircle(null, null, 30, 0.12, bottom: -15, right: -5),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    child: Text(
                      widget.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BACK ---
  Widget _buildBack(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            _buildCircle(-10, -10, 25, 0.1),
            const Center(
              child: Text(
                "Plus d'information",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STYLE ---
  BoxDecoration _cardDecoration(List<Color> colors) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: 0.4),
          offset: const Offset(3, 3),
          blurRadius: 8,
        ),
      ],
    );
  }

  Widget _buildCircle(
    double? top,
    double? left,
    double radius,
    double opacity, {
    double? bottom,
    double? right,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
