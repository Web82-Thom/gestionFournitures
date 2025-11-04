import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopStandController extends ChangeNotifier {
  final CollectionReference standsRef = FirebaseFirestore.instance.collection('stands');
  final CollectionReference boutiquesRef = FirebaseFirestore.instance.collection('boutiques');
  List<String> shops = [];
  List<String> stands = [];
  
  /// Récupérer la bonne référence Firestore
  CollectionReference getRef(bool isStand) {return isStand ? standsRef : boutiquesRef;}
  
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
                  const SnackBar(content: Text("Ajouter ✅")),
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
  
  /// Supprimer une boutique ou stand avec confirmation
  Future<void> confirmDelete(
    BuildContext context,
    String shopId,{
    bool isStand = false,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((isStand ? "Supprimer le stand ?" : "Supprimer la boutique ?")),
        content: Text((isStand ? "Êtes-vous sûr de vouloir supprimer ce stand ?" : "Êtes-vous sûr de vouloir supprimer cette boutique ?")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await getRef(isStand)
                  .doc(shopId)
                  .delete();

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text((isStand ?"Stand supprimé ✅": "Boutique supprimée ✅"))),
              );
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
  
  /// Récupère la liste des boutiques et des stands depuis Firestore
  Future<void> fetchShopsAndStands() async {
    try {
      // Récupération des boutiques
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('boutiques')
          .get();
      shops = shopSnapshot.docs.map((doc) => doc['name'] as String).toList();
      // Récupération des stands
      final standSnapshot = await FirebaseFirestore.instance
          .collection('stands')
          .get();
      stands = standSnapshot.docs.map((doc) => doc['name'] as String).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur fetchShopsAndStands: $e');
    }
  }
}
