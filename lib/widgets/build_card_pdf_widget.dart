import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gestion_fournitures/utils/pdf_helper.dart';
import '../controllers/pdf_controller.dart';


class BuildCardPdfWidget extends StatelessWidget {
  final Reference fileRef;
  final BuildContext parentContext;
  final PdfController pdfController;
  final String standId;
  final bool isShop;
  final bool canDelete;
  final Future<void> Function() reloadList;

  const BuildCardPdfWidget({
    Key? key,
    required this.fileRef,
    required this.parentContext,
    required this.pdfController,
    required this.standId,
    required this.isShop,
    required this.canDelete,
    required this.reloadList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(fileRef.fullPath),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: canDelete ? Colors.red : Colors.grey,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text("Supprimer", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: parentContext,
          builder: (_) => AlertDialog(
            title: const Text("Supprimer le PDF"),
            content: Text("Voulez-vous vraiment supprimer ${fileRef.name} ?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(parentContext, false),
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(parentContext, true),
                child: const Text(
                  "Supprimer",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await pdfController.deletePdfFile(
            fileRef: fileRef,
            standId: standId,
            isShop: isShop,
            context: parentContext,
            canDelete: canDelete,
          );

          await reloadList();
        }

        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(fileRef.name),
          trailing: Wrap(
            spacing: 10,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => PdfHelper.openPdf(fileRef.fullPath),
                tooltip: "Ouvrir le PDF",
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.green),
                onPressed: () => PdfHelper.sharePdf(fileRef.fullPath),
                tooltip: "Partager le PDF",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
