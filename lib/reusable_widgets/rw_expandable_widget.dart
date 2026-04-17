import 'package:delivery_app/tools/default_colors.dart'; // Import de tes couleurs
import 'package:flutter/material.dart';

class RwExpandableWidget extends StatefulWidget {
  final Widget child;

  const RwExpandableWidget({super.key, required this.child});

  @override
  State<RwExpandableWidget> createState() => _RwExpandableWidgetState();
}

class _RwExpandableWidgetState extends State<RwExpandableWidget> {
  late bool _isExpanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    _isExpanded = width > 900;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panneau de contenu
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        // Bouton avec Texte (Couleur Primaire)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              style: ElevatedButton.styleFrom(
                backgroundColor: DefaultColors.primary,
                // Ta couleur primaire
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              icon: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down, size: 20),
              ),
              label: Text(
                _isExpanded ? "MASQUER LES FILTRES" : "AFFICHER LES FILTRES",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
