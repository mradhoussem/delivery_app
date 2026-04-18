import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/pdf_payed_packages.dart';
import 'package:flutter/material.dart';

class RdPrintSavePayedPackages {
  static Future<void> show(BuildContext context, List<PackageModel> packages, String period) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: const [
            Icon(Icons.payments_rounded, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Rapport Colis Payes", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Periode: $period", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Nombre de colis: ${packages.length}"),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Column(
            children: [
              _buildBtn(context, "IMPRIMER", Icons.print, DefaultColors.primary,
                      () => PdfPayedPackages.printList(packages, period)),
              const SizedBox(height: 10),
              _buildBtn(context, "ENREGISTRER PDF", Icons.save_alt, Colors.green,
                      () => PdfPayedPackages.saveList(packages, period)),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
            ],
          )
        ],
      ),
    );
  }

  static Widget _buildBtn(BuildContext context, String label, IconData icon, Color color, Function action) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          action();
          Navigator.pop(context);
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}