// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfWaitingPackages {
  static Future<void> printList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'colis_en_attente.pdf',
    );
  }

  static Future<void> saveList(List<PackageModel> packages) async {
    final bytes = await _buildBytes(packages);
    _downloadOnWeb(bytes, 'colis_en_attente.pdf');
  }

  static Future<Uint8List> _buildBytes(List<PackageModel> packages) async {
    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );

    final cellStyle = const pw.TextStyle(fontSize: 8);

    final total = packages.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => [

          pw.Text("Express Colis", style: titleStyle),
          pw.SizedBox(height: 4),

          pw.Text("Colis en attente", style: headerStyle),

          pw.SizedBox(height: 4),

          pw.Text(
            "Total: $total colis",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headers: [
              "Client",
              "Téléphone",
              "Gouvernorat",
              "Adresse",
              "Montant",
              "Crée par",
              "Date",
            ],
            data: packages.map((p) {
              return [
                "${p.firstName} ${p.lastName}",
                "${p.phone1}${p.phone2 != null ? ' / ${p.phone2}' : ''}",
                p.governorate.name,
                p.address,
                "${p.amount.toStringAsFixed(3)} TND",
                "${p.creatorUsername}",
                "${p.createdAt.day.toString().padLeft(2, '0')}/"
                    "${p.createdAt.month.toString().padLeft(2, '0')}/"
                    "${p.createdAt.year}",
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
