import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/history_controller.dart';
import 'package:gestion_fournitures/models/shop_model.dart';

class ProductController extends ChangeNotifier {
  final HistoryController historyController = HistoryController();

  /// Collections Firestore
  final CollectionReference stockRefShop = FirebaseFirestore.instance
      .collection('boutiques');
  final CollectionReference stockRefStands = FirebaseFirestore.instance
      .collection('stands');

  List<ShopStandModel> listStock = [];
  late final BuildContext context;

  String? shopId;
  String? shopName;

  /// Récupérer la bonne référence Firestore
  CollectionReference getStockRef(bool isStand) {
    return isStand ? stockRefStands : stockRefShop;
  }
  /// Supprimer un produit avec confirmation
  Future<void> confirmDelete(
    BuildContext context,
    String shopId,
    String shopName,
    String productId,
    String productName, {
    bool isStand = false,
  }) async {
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
              await getStockRef(
                isStand,
              ).doc(shopId).collection('stock').doc(productId).delete();

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
    String value, {
    bool isStand = false,
  }) async {
    int parsedValue = int.tryParse(value) ?? 0;
    final docRef = getStockRef(
      isStand,
    ).doc(shopId).collection('stock').doc(productId);

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
  Future<void> updateNameProduct(
    BuildContext context,
    int index,
    String shopId,
    String shopName, {
    bool isStand = false,
  }) async {
    final controller = TextEditingController(text: listStock[index].product);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9, // taille par défaut (90% de l’écran)
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Modifier le produit",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: "Nom du produit",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Annuler"),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty) {
                            await getStockRef(isStand) // 🔹 true si stand
                                .doc(shopId)
                                .collection('stock')
                                .doc(listStock[index].id)
                                .update({'product': newName});

                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Produit modifié ✅"),
                              ),
                            );
                          }
                        },
                        child: const Text("Modifier"),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  /// Ajouter un produit et un historique
  void addProductDialog(
    BuildContext context,
    String shopId,
    String shopName, {
    bool isStand = false,
  }) {
    final nameController = TextEditingController();
    final quantiteController = TextEditingController();
    final consommerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6, // taille par défaut (60% de l’écran)
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Ajouter un produit",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Nom du produit",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantiteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Quantité",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: consommerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Consommé",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Annuler"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final quantite =
                                  int.tryParse(quantiteController.text) ?? 0;
                              final consommer =
                                  int.tryParse(consommerController.text) ?? 0;

                              if (name.isNotEmpty) {
                                final newProduct = ShopStandModel(
                                  id: '',
                                  product: name,
                                  quantite: quantite,
                                  consommer: consommer,
                                  reste: quantite - consommer,
                                  commande: (quantite - consommer) < 10
                                      ? "⚠️"
                                      : "✅",
                                );

                                await getStockRef(isStand)
                                    .doc(shopId)
                                    .collection('stock')
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
                                  const SnackBar(
                                    content: Text("Produit ajouté ✅"),
                                  ),
                                );
                              }
                            },
                            child: const Text("Ajouter"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
