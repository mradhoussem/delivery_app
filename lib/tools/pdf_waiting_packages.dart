// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfWaitingPackages {
  static Future<void> printList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'colis_en_attente.pdf');
  }

  static Future<void> saveList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    _downloadOnWeb(bytes, 'colis_en_attente.pdf');
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
              pw.Text("Express Colis - Colis en attente", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Image(logoImage, width: 60),
            ],
          ),
          pw.Divider(thickness: 0.5),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(thickness: 1),
          pw.Center(child: pw.Text("contact@express-colis.com", style: const pw.TextStyle(fontSize: 9))),
        ]),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text("Total: ${packages.length} colis", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: ["Client", "Téléphone", "Gouvernorat", "Adresse", "Montant", "Crée par", "Date"],
            data: packages.map((p) => [
              "${p.firstName} ${p.lastName}",
              "${p.phone1}${p.phone2 != null ? ' / ${p.phone2}' : ''}",
              p.governorate.name, p.address, "${p.amount.toStringAsFixed(3)} TND", p.creatorUsername,
              "${p.createdAt.day.toString().padLeft(2, '0')}/${p.createdAt.month.toString().padLeft(2, '0')}/${p.createdAt.year}"
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