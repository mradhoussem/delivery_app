import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class PdfPackage {
  // ── Imprimer uniquement ──
  static Future<void> generateAndPrint(PackageModel package) async {
    final bytes = await _buildBytes(package);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'colis_${package.id}.pdf',
    );
  }

  // ── Sauvegarder uniquement ──
  static Future<void> saveAndPrint(PackageModel package) async {
    final bytes = await _buildBytes(package);
    _downloadOnWeb(bytes, 'colis_${package.id}.pdf');
  }

  static Future<Uint8List> _buildBytes(PackageModel package) async {
    final ttfRegular = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document(title: 'colis_${package.id}');

    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 10);
    final labelStyle = pw.TextStyle(font: ttfBold, fontSize: 5);
    final valueStyle = pw.TextStyle(font: ttfRegular, fontSize: 5);

    pw.TableRow buildRow(String label, String value) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: pw.Text(label, style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: pw.Text(value, style: valueStyle, softWrap: true),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(12),
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        build: (pw.Context context) => [
          pw.Center(child: pw.Text("Express Colis", style: titleStyle)),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Column(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: package.id,
                  width: 90,
                  height: 90,
                  drawText: false,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "ID: ${package.id}",
                  style: pw.TextStyle(font: ttfBold, fontSize: 5),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              buildRow("Prénom", package.firstName),
              buildRow("Nom", package.lastName),
              buildRow("Téléphone 1", package.phone1),
              if (package.phone2 != null && package.phone2!.isNotEmpty)
                buildRow("Téléphone 2", package.phone2!),
              buildRow("Gouvernorat", package.governorate.name),
              buildRow("Adresse", package.address),
              buildRow("Montant", "${package.amount.toStringAsFixed(3)} TND"),
              buildRow("Échange", package.isExchange ? "Oui" : "Non"),
              if (package.isExchange &&
                  package.packageDesignation != null &&
                  package.packageDesignation!.isNotEmpty)
                buildRow("Désignation", package.packageDesignation!),
              if (package.comment != null && package.comment!.isNotEmpty)
                buildRow("Commentaire", package.comment!),
              buildRow("Créé par", package.creatorUsername),
              buildRow(
                "Créé le",
                "${package.createdAt.day.toString().padLeft(2, '0')}/"
                    "${package.createdAt.month.toString().padLeft(2, '0')}/"
                    "${package.createdAt.year}  "
                    "${package.createdAt.hour.toString().padLeft(2, '0')}:"
                    "${package.createdAt.minute.toString().padLeft(2, '0')}",
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static void _downloadOnWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}