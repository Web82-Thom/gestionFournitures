import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/history_controller.dart';
import 'package:gestion_fournitures/controllers/product_controller.dart';
import 'package:gestion_fournitures/models/shop_model.dart';

class LaBoutiquePage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const LaBoutiquePage({super.key, required this.shopId, required this.shopName});

  @override
  State<LaBoutiquePage> createState() => ShopDetailsPage();
}

class ShopDetailsPage extends State<LaBoutiquePage> {
  final HistoryController historyController = HistoryController();
  final ProductController productController = ProductController();

  List<TextEditingController> _quantiteControllers = [];
  List<TextEditingController> _consoControllers = [];

  @override
  void dispose() {
    for (var c in _quantiteControllers) {
      c.dispose();
    }
    for (var c in _consoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsRef = productController.stockRefShop
        .doc(widget.shopId)
        .collection('stock');
    return Scaffold(
      appBar: AppBar(
        title: Text("La Boutique - ${widget.shopName}"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => productController.addProductDialog(
              context,
              widget.shopId,
              widget.shopName,
              isStand: false,
            ),

            tooltip: "Ajouter un produit",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: productsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucun produit pour ce stand"));
            }
            productController.listStock = snapshot.data!.docs
                .map((doc) => ShopStandModel.fromFirestore(doc))
                .toList();
            productController.listStock.sort(
              (a, b) =>
                  a.product.toLowerCase().compareTo(b.product.toLowerCase()),
            );
            // Synchroniser les controllers
            _quantiteControllers = List.generate(
              productController.listStock.length,
              (i) => TextEditingController(
                text: productController.listStock[i].quantite.toString(),
              ),
            );
            _consoControllers = List.generate(
              productController.listStock.length,
              (i) => TextEditingController(
                text: productController.listStock[i].consommer.toString(),
              ),
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
                        itemCount: productController.listStock.length,
                        itemBuilder: (context, index) {
                          final product = productController.listStock[index];
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
                                              text: product.product,
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
                                                    await productController
                                                        .stockRefShop
                                                        .doc(widget.shopId)
                                                        .collection('stock')
                                                        .doc(product.id)
                                                        .update({
                                                          'product': newName,
                                                        });
                                                    if (!context.mounted) {
                                                      return;
                                                    }
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
                                          productController.confirmDelete(
                                            context,
                                            widget.shopId,
                                            widget.shopName,
                                            product.id,
                                            product.product,
                                          ),
                                      child: Text(
                                        product.product,
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
                                      onSubmitted: (val) =>
                                          productController.updateCell(
                                            context,
                                            widget.shopId,
                                            widget.shopName,
                                            product.id,
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
                                      onSubmitted: (val) =>
                                          productController.updateCell(
                                            context,
                                            widget.shopId,
                                            widget.shopName,
                                            product.id,
                                            'consommer',
                                            val,
                                          ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Center(
                                    child: Text(product.reste.toString()),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Center(child: Text(product.commande)),
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
