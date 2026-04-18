import 'dart:typed_data';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class PdfPermanentReturn {
  static Future<void> printList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'retour_definitif.pdf',
    );
  }

  static Future<void> saveList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    if (kIsWeb) {
      _downloadOnWeb(bytes, 'retour_definitif.pdf');
    } else {
      // For mobile, Printing.sharePdf is usually preferred for "saving"
      await Printing.sharePdf(bytes: bytes, filename: 'retour_definitif.pdf');
    }
  }

  static Future<Uint8List> _buildBytes(List<PackageModel> packages) async {
    final pdf = pw.Document();
    final headerStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final cellStyle = const pw.TextStyle(fontSize: 9);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Express Colis - Retour Definitif", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text("${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text("Total des retours: ${packages.length}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey),
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headers: ["Code", "Client", "Gouvernorat", "Montant", "Date Création"],
            data: packages.map((p) {
              return [
                p.id.substring(0, 8).toUpperCase(), // Showing short ID as reference
                "${p.firstName} ${p.lastName}",
                p.governorate.name,
                "${p.amount.toStringAsFixed(3)} TND",
                "${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}",
              ];
            }).toList(),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static void _downloadOnWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}