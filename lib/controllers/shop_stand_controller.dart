import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopStandController extends ChangeNotifier {
  final CollectionReference standsRef = FirebaseFirestore.instance.collection('stands');
  final CollectionReference boutiquesRef = FirebaseFirestore.instance.collection('boutiques');
  /// 🔹 Ajouter un stand
  void addStandDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter un stand"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nom du stand"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await standsRef.add({
                  'name': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Stand ajouté ✅")),
                );
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Ajouter une boutique
  void addBoutiqueDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter une boutique"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nom de la boutique"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await boutiquesRef.add({
                  'name': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Boutique ajoutée ✅")),
                );
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }
}
