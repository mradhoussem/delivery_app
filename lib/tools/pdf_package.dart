// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPackage {
  static Future<void> generateAndPrint(PackageModel package) async {
    final bytes = await _buildBytes(package);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'colis_${package.id}.pdf');
  }

  static Future<void> saveAndPrint(PackageModel package) async {
    final bytes = await _buildBytes(package);
    _downloadOnWeb(bytes, 'colis_${package.id}.pdf');
  }

  static Future<Uint8List> _buildBytes(PackageModel package) async {
    final ttfRegular = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final ByteData logoData = await rootBundle.load(ImagesFiles.logo);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final pdf = pw.Document(title: 'colis_${package.id}');

    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 7);
    final labelStyle = pw.TextStyle(font: ttfBold, fontSize: 4);
    final valueStyle = pw.TextStyle(font: ttfRegular, fontSize: 4);

    pw.TableRow buildRow(String label, String value) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(label, style: labelStyle)),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(value, style: valueStyle, softWrap: true)),
        ],
      );
    }

    pdf.addPage(
      pw.Page( // Utilisation de Page au lieu de MultiPage pour un contrôle total des marges
        pageFormat: PdfPageFormat.a6,
        margin: pw.EdgeInsets.zero, // On supprime toutes les marges par défaut
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(10), // Padding interne contrôlé
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Express Colis", style: titleStyle),
                  pw.Image(logoImage, width: 45),
                ],
              ),
              pw.Divider(thickness: 0.5, height: 5), // Height réduit pour coller au contenu
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: package.id, width: 75, height: 75, drawText: false),
                      pw.SizedBox(height: 2),
                      pw.Text("ID: ${package.id}", style: pw.TextStyle(font: ttfBold, fontSize: 5)),
                    ],
                  ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("EXPÉDITEUR :", style: pw.TextStyle(font: ttfBold, fontSize: 5, color: PdfColors.grey700)),
                      pw.Text(package.creatorUsername, style: pw.TextStyle(font: ttfBold, fontSize: 6)),
                      pw.Text("Matricule fiscale :", style: pw.TextStyle(font: ttfBold , fontSize: 5)),
                      pw.Text(package.creatorTaxId, style: pw.TextStyle(font: ttfBold , fontSize: 5,)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(3)},
                children: [
                  buildRow("Prénom", package.firstName),
                  buildRow("Nom", package.lastName),
                  buildRow("Téléphone 1", package.phone1),
                  if (package.phone2 != null && package.phone2!.isNotEmpty) buildRow("Téléphone 2", package.phone2!),
                  buildRow("Gouvernorat", package.governorate.name),
                  buildRow("Adresse", package.address),
                  buildRow("Montant", "${package.amount.toStringAsFixed(3)} TND"),
                  buildRow("Échange", package.isExchange ? "Oui" : "Non"),
                  if (package.isExchange && package.packageDesignation != null) buildRow("Désignation", package.packageDesignation!),
                  if (package.comment != null) buildRow("Commentaire", package.comment!),
                  buildRow("Créé par", package.creatorUsername),
                  buildRow("Créé le", "${package.createdAt.day.toString().padLeft(2, '0')}/${package.createdAt.month.toString().padLeft(2, '0')}/${package.createdAt.year}"),
                ],
              ),
              pw.Spacer(), // Pousse le texte de contact vers le bas
              pw.Divider(thickness: 0.5, height: 5),
              pw.Center(child: pw.Text("commercial.expresscolis@gmail.com", style: const pw.TextStyle(fontSize: 5))),
            ],
          ),
        ),
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