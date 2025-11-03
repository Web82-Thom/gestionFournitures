// lib/widgets/build_card_pdf_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:gestion_fournitures/controllers/pdf_controller.dart';

class BuildCardPdfWidget extends StatelessWidget {
  final File file;
  final String? fileName; // ✅ optionnel
  final BuildContext parentContext;
  final PdfController pdfController;
  final String standId;
  final bool isShop;
  final bool canDelete;
  final Future<void> Function() reloadList;

  const BuildCardPdfWidget({
    super.key,
    required this.file,
    this.fileName, // ✅ optionnel
    required this.parentContext,
    required this.pdfController,
    required this.standId,
    required this.isShop,
    required this.canDelete,
    required this.reloadList,
  });

  @override
  Widget build(BuildContext context) {
    final name = fileName ?? p.basename(file.path); // ✅ fallback auto

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
        title: Text(name, overflow: TextOverflow.ellipsis),
        trailing: canDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Supprimer le PDF ?"),
                      content: Text("Voulez-vous supprimer « $name » ?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Supprimer",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await pdfController.deletePdf(file); // ta fonction existante
                    await reloadList();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("« $name » supprimé ✅")),
                      );
                    }
                  }
                },
              )
            : null,
        onTap: () async => pdfController.openPdf(file),
      ),
    );
  }
}
