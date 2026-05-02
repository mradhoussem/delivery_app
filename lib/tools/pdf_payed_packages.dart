// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPayedPackages {
  static Future<void> printList(List<PackageModel> packages, String period) async {
    final bytes = await _buildBytes(packages, period);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'rapport_paye_$period.pdf');
  }

  static Future<void> saveList(List<PackageModel> packages, String period) async {
    final bytes = await _buildBytes(packages, period);
    _downloadOnWeb(bytes, 'rapport_paye_$period.pdf');
  }

  static Future<Uint8List> _buildBytes(List<PackageModel> packages, String period) async {
    final pdf = pw.Document();
    final ByteData logoData = await rootBundle.load(ImagesFiles.logo);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    double totalBrut = 0;
    double totalFrais = 0;
    for (var p in packages) {
      totalBrut += p.amount;
      totalFrais += p.deliveryCost;
    }
    double totalNet = totalBrut - totalFrais;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Express Colis - Rapport de Paiement", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Image(logoImage, width: 60),
            ],
          ),
          pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text("Periode: $period", style: const pw.TextStyle(fontSize: 12))),
          pw.SizedBox(height: 5),
          pw.Divider(thickness: 1),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(thickness: 1),
          pw.Center(child: pw.Text("commercial.expresscolis@gmail.com", style: const pw.TextStyle(fontSize: 9))),
        ]),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text("Resume des Totaux", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 1, color: PdfColors.black),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            headers: ["Total Brut (TND)", "Total Frais (TND)", "Total Net (TND)"],
            data: [[totalBrut.toStringAsFixed(3), totalFrais.toStringAsFixed(3), totalNet.toStringAsFixed(3)]],
            cellAlignment: pw.Alignment.center,
            cellHeight: 30,
          ),
          pw.SizedBox(height: 30),
          pw.Text("Details par Colis", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: ["Date", "Client", "Gouvernorat", "Crée par", "Montant Brut", "Frais", "Montant Net"],
            data: packages.map((p) => [
              "${p.createdAt.day.toString().padLeft(2, '0')}/${p.createdAt.month.toString().padLeft(2, '0')}/${p.createdAt.year}",
              "${p.firstName} ${p.lastName}", p.governorate.name, p.creatorUsername,
              p.amount.toStringAsFixed(3), p.deliveryCost.toStringAsFixed(3), (p.amount - p.deliveryCost).toStringAsFixed(3)
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