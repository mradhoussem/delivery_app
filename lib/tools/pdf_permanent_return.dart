// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPermanentReturn {
  static Future<void> printList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'retour_definitif.pdf');
  }

  static Future<void> saveList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    _downloadOnWeb(bytes, 'retour_definitif.pdf');
  }

  static Future<Uint8List> _buildBytes(List<PackageModel> packages) async {
    final pdf = pw.Document();
    final ByteData logoData = await rootBundle.load(ImagesFiles.logo);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Express Colis - Retour Definitif", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Image(logoImage, width: 60),
            ],
          ),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}")),
          pw.Divider(thickness: 1),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(thickness: 1),
          pw.Center(child: pw.Text("commercial.expresscolis@gmail.com", style: const pw.TextStyle(fontSize: 9))),
        ]),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text("Total des retours: ${packages.length}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ["Code", "Client", "Gouvernorat", "Crée par", "Montant", "Date Création"],
            data: packages.map((p) => [
              p.id.substring(0, 8).toUpperCase(),
              "${p.firstName} ${p.lastName}", p.governorate.name, p.creatorUsername,
              "${p.amount.toStringAsFixed(3)} TND", "${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}"
            ]).toList(),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static void _downloadOnWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute('download', filename)..click();
    html.Url.revokeObjectUrl(url);
  }
}