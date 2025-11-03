import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_fournitures/controllers/product_controller.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';

/// Page pour afficher les détails d'une boutique ou d'un stand
class ShopOrStandDetailsPage extends StatefulWidget {
  final String id;
  final String name;
  final bool isShop;

  const ShopOrStandDetailsPage({
    Key? key,
    required this.id,
    required this.name,
    this.isShop = true,
  }) : super(key: key);

  @override
  State<ShopOrStandDetailsPage> createState() => _ShopOrStandDetailsPageState();
}

class _ShopOrStandDetailsPageState extends State<ShopOrStandDetailsPage> {
  final ProductController productController = ProductController();

  List<TextEditingController> _quantiteControllers = [];
  List<TextEditingController> _consoControllers = [];

  String role = '';
  bool canEditProducts = false;
  bool isAdmin = false;
  // Rôles autorisés pour modifier / supprimer / renommer les produits 
  final List<String> allowedRoles = [
    'Administrateur',
    'Directeur Général',
    'Directeur de Boutique',
    'Chef de Boutique',
    'Chef de Stand',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!doc.exists) return;

    final userData = doc.data()!;
    final r = userData['role'] ?? '';

    setState(() {
      role = r;
      isAdmin = role == 'Administrateur';
      canEditProducts = allowedRoles.contains(role);
    });
  }

  @override
  void dispose() {
    for (final c in _quantiteControllers) c.dispose();
    for (final c in _consoControllers) c.dispose();
    super.dispose();
  }

  void _syncControllers() {
    // Qté controllers
    if (_quantiteControllers.length != productController.listStock.length) {
      for (final c in _quantiteControllers) c.dispose();
      _quantiteControllers = productController.listStock
          .map((p) => TextEditingController(text: p.quantite.toString()))
          .toList();
    } else {
      for (int i = 0; i < _quantiteControllers.length; i++) {
        final text = productController.listStock[i].quantite.toString();
        if (_quantiteControllers[i].text != text) {
          _quantiteControllers[i].text = text;
        }
      }
    }

    // Conso controllers
    if (_consoControllers.length != productController.listStock.length) {
      for (final c in _consoControllers) c.dispose();
      _consoControllers = productController.listStock
          .map((p) => TextEditingController(text: p.consommer.toString()))
          .toList();
    } else {
      for (int i = 0; i < _consoControllers.length; i++) {
        final text = productController.listStock[i].consommer.toString();
        if (_consoControllers[i].text != text) {
          _consoControllers[i].text = text;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockCollection = productController
        .getStockRef(!widget.isShop)
        .doc(widget.id)
        .collection('stock');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(
          widget.isShop ? 'Boutique - ${widget.name}' : 'Stand - ${widget.name}',
        ),
        actions: [
          IconButton(
            onPressed: () => productController.addProductDialog(
              context,
              widget.id,
              widget.name,
              isStand: !widget.isShop,
            ),
            icon: const Icon(Icons.add),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: StreamBuilder<QuerySnapshot>(
            stream: stockCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Aucun produit pour ${widget.name}',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                      ),
                    ),
                  ),
                );
              }

              // Build listStock from Firestore docs
              productController.listStock = snapshot.data!.docs
                  .map((doc) => ShopStandModel.fromFirestore(doc))
                  .toList();

              productController.listStock.sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

              _syncControllers();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📦 Stock — ${widget.name}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                  ),
                  const SizedBox(height: 12),

                  // Header row
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        children: const [
                          Expanded(flex: 25, child: Center(child: Text('Produit', textAlign: TextAlign.center))),
                          Expanded(flex: 20, child: Center(child: Text('Qté', textAlign: TextAlign.center))),
                          Expanded(flex: 20, child: Center(child: Text('Conso', textAlign: TextAlign.center))),
                          Expanded(flex: 15, child: Center(child: Text('Reste', textAlign: TextAlign.center))),
                          Expanded(flex: 20, child: Center(child: Text('Cmd', textAlign: TextAlign.center))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Product list
                  Expanded(
                    child: ListView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: productController.listStock.length,
                      itemBuilder: (context, index) {
                        final p = productController.listStock[index];
                        final qtyController = _quantiteControllers[index];
                        final consoController = _consoControllers[index];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: index.isEven ? Colors.white : Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6),
                            child: Row(
                              children: [
                                // Product name
                                Expanded(
                                  flex: 25,
                                  child: Center(
                                    child: GestureDetector(
                                      onDoubleTap: canEditProducts
                                          ? () => productController.updateNameProduct(
                                                context,
                                                index,
                                                widget.id,
                                                widget.name,
                                                isStand: !widget.isShop,
                                              )
                                          : null,
                                      onLongPress: canEditProducts
                                          ? () => productController.confirmDelete(
                                                context,
                                                widget.id,
                                                widget.name,
                                                p.id,
                                                p.name,
                                                isStand: !widget.isShop,
                                              )
                                          : null,
                                      child: Text(
                                        p.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey.shade900),
                                      ),
                                    ),
                                  ),
                                ),

                                // Quantity editable
                                Expanded(
                                  flex: 20,
                                  child: Center(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextField(
                                        controller: qtyController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onSubmitted: (val) => productController.updateCell(
                                                  context,
                                                  widget.id,
                                                  widget.name,
                                                  p.id,
                                                  'quantite',
                                                  val,
                                                  isStand: !widget.isShop,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Conso editable
                                Expanded(
                                  flex: 20,
                                  child: Center(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextField(
                                        controller: consoController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onSubmitted: (val) => productController.updateCell(
                                                  context,
                                                  widget.id,
                                                  widget.name,
                                                  p.id,
                                                  'consommer',
                                                  val,
                                                  isStand: !widget.isShop,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Reste
                                Expanded(flex: 15, child: Center(child: Text(p.reste.toString()))),

                                // Cmd
                                Expanded(flex: 20, child: Center(child: Text(p.commande!))),
                              ],
                            ),
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
      ),
    );
  }
}
