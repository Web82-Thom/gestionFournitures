import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TurnoverController extends ChangeNotifier {
  /// Références Firestore
  final CollectionReference turnoverRefShop =
      FirebaseFirestore.instance.collection('boutiques');
  final CollectionReference turnoverRefStands =
      FirebaseFirestore.instance.collection('stands');

  /// Récupérer la bonne référence Firestore (Stand ou Boutique)
  CollectionReference getTurnoverRef(bool isStand) {
    return isStand ? turnoverRefStands : turnoverRefShop;
  }

  String monthName(int month) {
    const months = [
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ];
    return months[month - 1];
  }

  /// 🔹 Ajouter un chiffre d'affaire
  void addTurnoverDialog(
    BuildContext context,
    String shopId, {
    bool isStand = false,
  }) {
    final recetteController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Ajouter un chiffre d'affaire"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? "Sélectionner une date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        locale: const Locale('fr'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: recetteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Recette (€)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null) {
                  final recette = double.tryParse(recetteController.text) ?? 0;

                  await getTurnoverRef(isStand)
                      .doc(shopId)
                      .collection('chiffreAffaire')
                      .add({
                    'date':
                        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    'date_ts': selectedDate,
                    'recette': recette,
                    'isShop': !isStand,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chiffre d'affaire ajouté ✅")),
                  );
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Modifier un chiffre d'affaire
  void editTurnoverDialog(
    BuildContext context,
    String shopId,
    String docId,
    Map<String, dynamic> data, {
    bool isStand = false,
  }) {
    final dateController = TextEditingController(text: data['date'] ?? '');
    final recetteController = TextEditingController(text: (data['recette'] ?? '').toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le chiffre d'affaire"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date (JJ/MM/AAAA)"),
            ),
            TextField(
              controller: recetteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Recette (€)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDate = dateController.text.trim();
              final newRecette = double.tryParse(recetteController.text) ?? 0;

              DateTime? dateTs;
              final parts = newDate.split('/');
              if (parts.length == 3) {
                final d = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                final y = int.tryParse(parts[2]);
                if (d != null && m != null && y != null) {
                  dateTs = DateTime(y, m, d);
                }
              }

              final updateMap = {
                'date': newDate,
                'recette': newRecette,
                'isShop': !isStand,
              };
              if (dateTs != null) updateMap['date_ts'] = dateTs;

              await getTurnoverRef(isStand)
                  .doc(shopId)
                  .collection('chiffreAffaire')
                  .doc(docId)
                  .update(updateMap);

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chiffre d'affaire modifié ✅")),
              );
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Supprimer un chiffre d'affaire
  void deleteTurnoverDialog(
    BuildContext context,
    String shopId,
    String docId, {
    bool isStand = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous supprimer ce chiffre d'affaire ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await getTurnoverRef(isStand)
          .doc(shopId)
          .collection('chiffreAffaire')
          .doc(docId)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chiffre d'affaire supprimé ✅")),
      );
    }
  }
}
