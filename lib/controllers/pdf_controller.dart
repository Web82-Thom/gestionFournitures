import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'turnover_controller.dart'; // pour monthName()

class PdfController {
  final TurnoverController turnoverController = TurnoverController();

  /// Générer le PDF mensuel et le sauvegarder sur Firebase
  Future<void> generateMonthlyPdf({
    required ShopStandModel stand,
    required bool isShop,
    required int month,
    required int year,
    required double total,
    required List<Map<String, dynamic>> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Rapport du mois de ${turnoverController.monthName(month)} $year",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["Date", "Recette (€)", "Créé par"],
              data: data.map((d) => [
                d['date'],
                d['recette'].toStringAsFixed(2),
                d['createdBy'],
              ]).toList(),
            ),
            pw.Divider(),
            pw.Text(
              "Total : $total €",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    Uint8List bytes = await pdf.save();

    final storageRef = FirebaseStorage.instance.ref().child(
      "${isShop ? 'boutiques' : 'stands'}/${stand.id}/rapports/${year}_${month}.pdf",
    );

    await storageRef.putData(bytes);
    final downloadUrl = await storageRef.getDownloadURL();

    final pdfCollection = isShop
        ? FirebaseFirestore.instance
            .collection('boutiques')
            .doc(stand.id)
            .collection('pdfReports')
        : FirebaseFirestore.instance
            .collection('stands')
            .doc(stand.id)
            .collection('pdfReports');

    await pdfCollection.add({
      'month': month,
      'year': year,
      'total': total,
      'url': downloadUrl,
      'createdAt': Timestamp.now(),
    });
  }
  // Supprime un PDF du stockage et de Firestore
  Future<void> deletePdfFile({
    required Reference fileRef,
    required String standId,
    required bool isShop,
    required BuildContext context,
    required bool canDelete,
  }) async {
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accès refusé 🔒")),
      );
      return;
    }

    // 🔹 Boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le PDF"),
        content: Text("Voulez-vous vraiment supprimer ${fileRef.name} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 🔹 On récupère l’URL du fichier avant suppression
      final url = await fileRef.getDownloadURL();

      // 🔹 On supprime le fichier du stockage
      await FirebaseStorage.instance.ref(fileRef.fullPath).delete();

      // 🔹 On cherche la référence du PDF dans Firestore
      final pdfCollection = isShop
          ? FirebaseFirestore.instance
              .collection('boutiques')
              .doc(standId)
              .collection('pdfReports')
          : FirebaseFirestore.instance
              .collection('stands')
              .doc(standId)
              .collection('pdfReports');

      final snapshot = await pdfCollection.where('url', isEqualTo: url).get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${fileRef.name} supprimé ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la suppression : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


