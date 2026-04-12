import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/pdf_package.dart';
import 'package:flutter/material.dart';

class RdPrintSavePackage {
  static Future<void> show(
      BuildContext context,
      PackageModel package, {
        bool doublePopNavigation = false, // Added param with default true
      }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Column(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
              size: 70,
            ),
            const SizedBox(height: 15),
            const Text(
              "Succès !",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        content: const Text(
          "Le colis a été ajouté avec succès. Souhaitez-vous imprimer l'étiquette maintenant ?",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              // --- Main Action: Print ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PdfPackage.generateAndPrint(package);
                    if (ctx.mounted) {
                      Navigator.pop(ctx); // Always close dialog
                      if (doublePopNavigation) Navigator.pop(context); // Optional pop
                    }
                  },
                  icon: const Icon(Icons.print, color: Colors.white, size: 20),
                  label: const Text(
                    "IMPRIMER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DefaultColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- Secondary Action: Save ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PdfPackage.saveAndPrint(package);
                    if (ctx.mounted) {
                      Navigator.pop(ctx); // Always close dialog
                      if (doublePopNavigation) Navigator.pop(context); // Optional pop
                    }
                  },
                  icon: const Icon(
                    Icons.save_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    "ENREGISTRER PDF",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // --- Dismiss Action ---
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Always close dialog
                  if (doublePopNavigation) Navigator.pop(context); // Optional pop
                },
                child: Text(
                  "PLUS TARD",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}