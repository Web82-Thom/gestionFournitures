import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_fournitures/controllers/product_controller.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';
import 'package:gestion_fournitures/widgets/build_editable_cell_widget.dart';

class ShopOrStandDetailsPage extends StatefulWidget {
  final String id;
  final String name;
  final bool isShop;

  const ShopOrStandDetailsPage({
    super.key,
    required this.id,
    required this.name,
    this.isShop = true,
  });

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
    for (final c in _quantiteControllers) {
      c.dispose();
    }
    for (final c in _consoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    // Quantité
    if (_quantiteControllers.length != productController.listStock.length) {
      for (final c in _quantiteControllers) {
        c.dispose();
      }
      _quantiteControllers = productController.listStock
          .map((p) => TextEditingController(text: p.quantite.toString()))
          .toList();
    }

    // Consommation
    if (_consoControllers.length != productController.listStock.length) {
      for (final c in _consoControllers) c.dispose();
      _consoControllers = productController.listStock
          .map((p) => TextEditingController(text: p.consommer.toString()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stockCollection = productController
        .getStockRef(!widget.isShop)
        .doc(widget.id)
        .collection('stock');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isShop ? "🏬 Boutique - ${widget.name}" : "🧁 Stand - ${widget.name}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        elevation: 3,
        shadowColor: Colors.black26,
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
                    elevation: 3,
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "Aucun produit trouvé pour ${widget.name}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }
      
              productController.listStock = snapshot.data!.docs
              .map((doc) => ShopStandModel.fromFirestore(doc))
              .toList();
      
              productController.listStock.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
      
              _syncControllers();
      
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📦 Stock — ${widget.name}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
      
                  // 🧱 En-tête
                  Card(
                    elevation: 2,
                    color: colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 25, child: Center(child: Text('Produit'))),
                          Expanded(flex: 20, child: Center(child: Text('Qté'))),
                          Expanded(flex: 20, child: Center(child: Text('Conso'))),
                          Expanded(flex: 15, child: Center(child: Text('Reste'))),
                          Expanded(flex: 20, child: Center(child: Text('Cmd'))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
      
                  // 📄 Liste des produits
                  Expanded(
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: productController.listStock.length,
                      itemBuilder: (context, index) {
                        final p = productController.listStock[index];
                        final qtyController = _quantiteControllers[index];
                        final consoController = _consoControllers[index];
                        final isEven = index.isEven;
      
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isEven
                                ? colorScheme.surface
                                : colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            child: Row(
                              children: [
                                // 🏷️ Produit
                                Expanded(
                                  flex: 25,
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
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
      
                                // 📦 Qté
                                Expanded(
                                  flex: 20,
                                  child: BuildEditableCellWidget(
                                    controller: qtyController,
                                    onSubmit: (val) => productController.updateCell(
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
      
                                // ⚡ Conso
                                Expanded(
                                  flex: 20,
                                  child: BuildEditableCellWidget(
                                    controller: consoController,
                                    onSubmit: (val) => productController.updateCell(
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
                                // 📊 Reste
                                Expanded(
                                  flex: 15,
                                  child: Center(
                                    child: Text(
                                      p.reste.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
      
                                // 🧾 Commande
                                Expanded(
                                  flex: 20,
                                  child: Center(
                                    child: Text(
                                      p.commande ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: p.commande == "⚠️"
                                        ? Colors.red
                                        : Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
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
      floatingActionButton: canEditProducts
      ? FloatingActionButton.extended(
          onPressed: () => productController.addProductDialog(
            context,
            widget.id,
            widget.name,
            isStand: !widget.isShop,
          ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
          label: const Text(
            "Ajouter un produit",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        )
      : null,
    );
  }
}
