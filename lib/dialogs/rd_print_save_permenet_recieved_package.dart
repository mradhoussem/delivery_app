import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/pdf_permanent_return.dart'; // NEW IMPORT
import 'package:flutter/material.dart';

class RdPrintSavePermanentReturn {
  static Future<void> show(
      BuildContext context,
      List<PackageModel> packages,
      ) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: const [
            Icon(Icons.assignment_return, color: Colors.redAccent, size: 70),
            SizedBox(height: 15),
            Text("Retours Définitifs", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Vous avez ${packages.length} colis en retour définitif.\nSouhaitez-vous générer le PDF ?",
          textAlign: TextAlign.center,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                _buildButton(
                  label: "IMPRIMER LISTE",
                  icon: Icons.print,
                  color: DefaultColors.primary,
                  onTap: () async {
                    await PdfPermanentReturn.printList(packages);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                _buildButton(
                  label: "TÉLÉCHARGER PDF",
                  icon: Icons.download,
                  color: Colors.green,
                  onTap: () async {
                    await PdfPermanentReturn.saveList(packages);
                    Navigator.pop(ctx);
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ANNULER"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  static Widget _buildButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}