import 'package:flutter/material.dart';

class RwStatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const RwStatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    double cardWidth = isMobile ? 140 : 180;
    double cardHeight = isMobile ? 90 : 100;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: _cardDecoration(gradientColors),
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
                        title,
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
                          value,
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
          color: colors.last.withAlpha((255 * 0.4).toInt()),
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
        backgroundColor: Colors.white.withAlpha((255 * opacity).toInt()),
      ),
    );
  }
}