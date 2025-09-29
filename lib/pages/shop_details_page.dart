import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/shop_model.dart';

class LaBoutiquePage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const LaBoutiquePage({
    Key? key,
    required this.shopId,
    required this.shopName,
  }): super(key: key);

  @override
  State<LaBoutiquePage> createState() => ShopDetailsPage();
}

class ShopDetailsPage extends State<LaBoutiquePage> {
  final CollectionReference stockRef = FirebaseFirestore.instance.collection(
    'boutiques',
  );
  

  List<TextEditingController> _quantiteControllers = [];
  List<TextEditingController> _consoControllers = [];
  List<ShopStandModel> listStock = [];

  void dispose() {
    for (var c in _quantiteControllers) c.dispose();
    for (var c in _consoControllers) c.dispose();
    super.dispose();
  }
  /// Supprimer un produit avec confirmation
  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                  .doc(widget.shopId)
                  .collection('stockToulouse')
                  .doc(productId)
                  .delete();
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
  Future<void> _updateCell(String productId, String key, String value) async {
    int parsedValue = int.tryParse(value) ?? 0;
    DocumentReference docRef = stockRef
        .doc(widget.shopId)
        .collection('stockToulouse')
        .doc(productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final quantite = key == 'quantite'
          ? parsedValue
          : int.tryParse(data['quantite'].toString()) ?? 0;
      final consommer = key == 'consommer'
          ? parsedValue
          : int.tryParse(data['consommer'].toString()) ?? 0;
      final reste = quantite - consommer;
      final commande = reste < 10 ? "⚠️" : "✅";

      transaction.update(docRef, {
        'quantite': quantite,
        'consommer': consommer,
        'reste': reste,
        'commande': commande,
      });
    });
  }
  // void _updateControllers() {
  //   _quantiteControllers = listStock
  //       .map((p) => TextEditingController(text: p.quantite.toString()))
  //       .toList();
  //   _consoControllers = listStock
  //       .map((p) => TextEditingController(text: p.consommer.toString()))
  //       .toList();
  // }

  /// Modifier le nom du produit
  void modifierNomProduit(int index) {
    final controller = TextEditingController(text: listStock[index].produits);

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
                  'produits': newName,
                });
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
  void _addProductDialog() {
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
                  produits: name,
                  quantite: quantite,
                  consommer: consommer,
                  reste: quantite - consommer,
                  commande: (quantite - consommer) < 10 ? "⚠️" : "✅",
                );
                await stockRef
                    .doc(widget.shopId)
                    .collection('stockToulouse')
                    .add(newProduct.toMap());
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

  @override
  Widget build(BuildContext context) {
    final productsRef = stockRef.doc(widget.shopId).collection('stockToulouse');

    return Scaffold(
      appBar: AppBar(
        title: Text("La Boutique - ${widget.shopName}"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProductDialog,
            tooltip: "Ajouter un produit",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: productsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const Center(child: Text("Aucun produit pour ce stand"));
            listStock = snapshot.data!.docs
                .map((doc) => ShopStandModel.fromFirestore(doc))
                .toList();
            listStock.sort(
              (a, b) =>
                  a.produits.toLowerCase().compareTo(b.produits.toLowerCase()),
            );
            // Synchroniser les controllers
_quantiteControllers = List.generate(
  listStock.length,
  (i) => TextEditingController(text: listStock[i].quantite.toString()),
);

_consoControllers = List.generate(
  listStock.length,
  (i) => TextEditingController(text: listStock[i].consommer.toString()),
);

            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📦 Stock boutique de ${widget.shopName}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // En-tête
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 25,
                            child: Text(
                              'Produits',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              'Qté stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              'Conso',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 15,
                            child: Text(
                              'Reste',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              'Cmd',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tableau
                    Expanded(
                      child: ListView.builder(
                        itemCount: listStock.length,
                        itemBuilder: (context, index) {
                          final p = listStock[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.blue.shade50
                                  : Colors.white,
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              children: [
                                // Double tap pour modifier le produit
                                Expanded(
                                  flex: 25,
                                  child: Center(
                                    child: GestureDetector(
                                      onDoubleTap: () {
                                        final controller =
                                            TextEditingController(
                                              text: p.produits,
                                            );
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              "Modifier le produit",
                                            ),
                                            content: TextField(
                                              controller: controller,
                                              decoration: const InputDecoration(
                                                labelText: "Nom du produit",
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text("Annuler"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final newName = controller
                                                      .text
                                                      .trim();
                                                  if (newName.isNotEmpty) {
                                                    await stockRef
                                                        .doc(widget.shopId)
                                                        .collection('stockToulouse')
                                                        .doc(p.id)
                                                        .update({
                                                          'produits': newName,
                                                        });
                                                    if (!context.mounted)
                                                      return;
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Produit modifié ✅",
                                                        ),
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
                                      onLongPress: () =>
                                          _confirmDelete(p.id),
                                      child: Text(
                                        p.produits,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Center(
                                    child: TextField(
                                      controller: _quantiteControllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      onSubmitted: (val) => _updateCell(
                                        p.id,
                                        'quantite',
                                        val,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Center(
                                    child: TextField(
                                      controller: _consoControllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      onSubmitted: (val) => _updateCell(
                                        p.id,
                                        'consommer',
                                        val,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Center(
                                    child: Text(p.reste.toString()),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Center(child: Text(p.commande)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
