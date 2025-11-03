import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'dart:typed_data';
import 'turnover_controller.dart'; // pour monthName()

class PdfController {
  final TurnoverController turnoverController = TurnoverController();

  /// Génère un PDF mensuel et l’enregistre localement sur le téléphone
  Future<void> generateMonthlyPdfLocally({
    required ShopStandModel stand,
    required bool isShop,
    required int month,
    required int year,
    required double total,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      final pdf = pw.Document();

      final monthName =
          DateFormat.MMMM('fr_FR').format(DateTime(year, month)).capitalize();
      final title = "${stand.name} - $monthName $year";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  "Chiffre d'affaire - $title",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Date", "Recette (€)", "Créé par"],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                cellAlignment: pw.Alignment.center,
                data: data.map((item) {
                  final date = (item['parsedDate'] as DateTime?) ??
                      DateTime.tryParse(item['date'] ?? '');
                  final formattedDate = date != null
                      ? DateFormat('dd/MM/yy').format(date)
                      : item['date'] ?? '';
                  return [
                    formattedDate,
                    (item['recette'] as double).toStringAsFixed(2),
                    item['createdBy'] ?? ''
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Total : ${total.toStringAsFixed(2)} €",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // 📁 Enregistrement dans le dossier Documents/ ou Downloads/
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath =
          "${directory.path}/CA_${stand.name}_${month.toString().padLeft(2, '0')}_$year.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      

      // ✅ Ouvre le fichier après génération
      await OpenFilex.open(file.path);

      debugPrint("PDF enregistré dans : $filePath");
    } catch (e) {
      debugPrint("Erreur PDF local : $e");
      rethrow;
    }
  }
  /// 🔹 Liste tous les PDFs enregistrés dans le dossier local
  Future<List<File>> loadLocalPdfFiles() async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final directory = Directory(dir.path);

    if (!directory.existsSync()) return [];

    final pdfs = directory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith(".pdf"))
        .toList();

    pdfs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return pdfs;
  }
  // Supprime un PDF du stockage et de Firestore
  Future<void> deletePdf(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }

Future<void> openPdf(File file) async {
  await OpenFilex.open(file.path);
}


}

extension StringCasing on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

