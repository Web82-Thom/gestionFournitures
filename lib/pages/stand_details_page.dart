import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/product_controller.dart';
import 'package:gestion_fournitures/models/shop_model.dart';

class StandDetailsPage extends StatefulWidget {
  final String standId;
  final String standName;

  const StandDetailsPage({
    super.key,
    required this.standId,
    required this.standName,
  });

  @override
  State<StandDetailsPage> createState() => _StandDetailPageState();
}

class _StandDetailPageState extends State<StandDetailsPage> {
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
    final productsRef = FirebaseFirestore.instance
        .collection('stands')
        .doc(widget.standId)
        .collection('stock'); // ⚠️ Vérifie bien ton nom de sous-collection

    return Scaffold(
      appBar: AppBar(title: Text("Stand : ${widget.standName}")),
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
              (a, b) => a.product.toLowerCase().compareTo(b.product.toLowerCase()),
            );

            _updateControllers();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📦 Stock Stand ${widget.standName}",
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
                      final p = productController.listStock[index];
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
                                    productController.modifierNomProduit(
                                      context,
                                      index,
                                      widget.standId,
                                      widget.standName,
                                      isStand: true,
                                    );
                                  },
                                  onLongPress: () => productController.confirmDelete(
                                    context,
                                    widget.standId,
                                    widget.standName,
                                    p.id,
                                    p.product,
                                    isStand: true,
                                  ),
                                  child: Text(
                                    p.product,
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
                                  onSubmitted: (val) => productController.updateCell(
                                    context,
                                    widget.standId,
                                    widget.standName,
                                    p.id,
                                    'quantite',
                                    val,
                                    isStand: true,
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
                                    widget.standId,
                                    widget.standName,
                                    p.id,
                                    'consommer',
                                    val,
                                    isStand: true,
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => productController.addProductDialog(
          context,
          widget.standId,
          widget.standName,
          isStand: true,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
