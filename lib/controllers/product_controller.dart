import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/history_controller.dart';
import 'package:gestion_fournitures/models/shop_model.dart';

class ProductController extends ChangeNotifier {
  final HistoryController historyController = HistoryController();
  final CollectionReference stockRef = FirebaseFirestore.instance.collection(
    'boutiques',
  );
  List<ShopStandModel> listStock = [];
  late final BuildContext context;
  String? shopId;
  String? shopName;

  /// Supprimer un produit avec confirmation
  Future<void> confirmDelete(
    BuildContext context,
    String shopId,
    String shopName,
    String productId,
    String productName,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le produit ?"),
        content: const Text("Êtes-vous sûr de vouloir supprimer ce produit ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await stockRef
                  .doc(shopId)
                  .collection('stockToulouse')
                  .doc(productId)
                  .delete();

              await historyController.addHistory(
                action: 'suppression',
                product: productName,
                quantite: 0,
                reste: 0,
                shopName: shopName,
              );

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Produit supprimé ✅")),
              );
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  /// Modifier Qté ou Conso
  Future<void> updateCell(
    BuildContext context,
    String shopId,
    String shopName,
    String productId,
    String key,
    String value,
  ) async {
    int parsedValue = int.tryParse(value) ?? 0;
    final docRef = stockRef
        .doc(shopId)
        .collection('stockToulouse')
        .doc(productId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final quantite = key == 'quantite'
          ? parsedValue
          : (data['quantite'] ?? 0);
      final consommer = key == 'consommer'
          ? parsedValue
          : (data['consommer'] ?? 0);
      final reste = quantite - consommer;
      final commande = reste < 10 ? "⚠️" : "✅";

      transaction.update(docRef, {
        'quantite': quantite,
        'consommer': consommer,
        'reste': reste,
        'commande': commande,
      });
      await historyController.addHistory(
        action: 'modification',
        product: data['product'] ?? '',
        quantite: parsedValue,
        reste: reste,
        shopName: shopName,
      );
    });
  }
  /// Modifier le nom du produit
  void modifierNomProduit(int index) {
    final controller = TextEditingController(text: listStock[index].product);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le produit"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nom du produit"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await stockRef.doc(listStock[index].id).update({
                  'product': newName,
                });
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Produit modifié ✅")),
                );
              }
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }
  /// Ajouter un produit
  void addProductDialog(BuildContext context, String shopId, String shopName) {
    final nameController = TextEditingController();
    final quantiteController = TextEditingController();
    final consommerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un produit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom du produit"),
            ),
            TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantité"),
            ),
            TextField(
              controller: consommerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Consommé"),
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
              final name = nameController.text.trim();
              final quantite = int.tryParse(quantiteController.text) ?? 0;
              final consommer = int.tryParse(consommerController.text) ?? 0;
              if (name.isNotEmpty) {
                final newProduct = ShopStandModel(
                  id: '',
                  product: name,
                  quantite: quantite,
                  consommer: consommer,
                  reste: quantite - consommer,
                  commande: (quantite - consommer) < 10 ? "⚠️" : "✅",
                );
                await stockRef
                    .doc(shopId)
                    .collection('stockToulouse')
                    .add(newProduct.toMap());
                await historyController.addHistory(
                  action: 'création',
                  product: name,
                  quantite: quantite,
                  reste: quantite - consommer,
                  shopName: shopName,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Produit ajouté ✅")),
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
