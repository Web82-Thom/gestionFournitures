import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/history_controller.dart';
import 'package:gestion_fournitures/controllers/product_controller.dart';
import 'package:gestion_fournitures/models/shop_model.dart';

class ShopDetailsPage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopDetailsPage({super.key, required this.shopId, required this.shopName});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final HistoryController historyController = HistoryController();
  final ProductController productController = ProductController();

  List<TextEditingController> _quantiteControllers = [];
  List<TextEditingController> _consoControllers = [];

  @override
  void dispose() {
    for (var c in _quantiteControllers) c.dispose();
    for (var c in _consoControllers) c.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _quantiteControllers = productController.listStock
        .map((p) => TextEditingController(text: p.quantite.toString()))
        .toList();
    _consoControllers = productController.listStock
        .map((p) => TextEditingController(text: p.consommer.toString()))
        .toList();
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
            tooltip: "Ajouter un produit",
            onPressed: () => productController.addProductDialog(
              context,
              widget.shopId,
              widget.shopName,
              isStand: false,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun produit pour cette boutique"));
          }

          productController.listStock = snapshot.data!.docs
              .map((doc) => ShopStandModel.fromFirestore(doc))
              .toList();

          productController.listStock.sort(
            (a, b) => a.product.toLowerCase().compareTo(b.product.toLowerCase()),
          );

          _updateControllers();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📦 Stock boutique de ${widget.shopName}",
                      style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: const Row(
                        children: [
                          Expanded(flex: 25, child: Text('Produits', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 20, child: Text('Qté stock', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 20, child: Text('Conso', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 15, child: Text('Reste', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 20, child: Text('Cmd', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tableau
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: productController.listStock.length,
                      itemBuilder: (context, index) {
                        final product = productController.listStock[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? Colors.blue.shade50 : Colors.white,
                            border: Border.all(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 25,
                                child: Center(
                                  child: InkWell(
                                    onTap: () => {
                                      print("On tap on ${product.product}"),
                                      productController.updateNameProduct(
                                      context,
                                      index,
                                      widget.shopId,
                                      widget.shopName,
                                      isStand: false,
                                    )
                                    },
                                    onLongPress: () => productController.confirmDelete(
                                      context,
                                      widget.shopId,
                                      widget.shopName,
                                      product.id,
                                      product.product,
                                      isStand: false,
                                    ),
                                    child: Text(product.product, textAlign: TextAlign.center),
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
                                    onSubmitted: (val) => productController.updateCell(
                                      context,
                                      widget.shopId,
                                      widget.shopName,
                                      product.id,
                                      'quantite',
                                      val,
                                      isStand: false,
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
                                    onSubmitted: (val) => productController.updateCell(
                                      context,
                                      widget.shopId,
                                      widget.shopName,
                                      product.id,
                                      'consommer',
                                      val,
                                      isStand: false,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(flex: 15, child: Center(child: Text(product.reste.toString()))),
                              Expanded(flex: 20, child: Center(child: Text(product.commande))),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
