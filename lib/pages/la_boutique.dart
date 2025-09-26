import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/shop_stock_model.dart';

class LaBoutiquePage extends StatefulWidget {
  const LaBoutiquePage({super.key});

  @override
  State<LaBoutiquePage> createState() => _LaBoutiquePageState();
}

class _LaBoutiquePageState extends State<LaBoutiquePage> {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('boutique');

  List<TextEditingController> _quantiteControllers = [];
  List<TextEditingController> _consoControllers = [];

  /// Ouvre une boîte de dialogue pour modifier le nom du produit
  void modifierNomProduit(ShopStockModel row) {
    final controller = TextEditingController(text: row.produits);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le produit"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nom du produit"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _collection.doc(row.id).update({'produits': newName});
                Navigator.pop(context);
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

  void _confirmDelete(ShopStockModel row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer le produit '${row.produits}' ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );

    if (confirmed == true) {
      await _collection.doc(row.id).delete();
    }
  }

  void _updateCell(ShopStockModel row, String key, String value) {
    int parsedValue = int.tryParse(value) ?? 0;
    if (parsedValue < 0) parsedValue = 0;
    if (key == 'consommer' && parsedValue > row.quantite) parsedValue = row.quantite;
    _collection.doc(row.id).update({key: parsedValue});
  }

  /// Ouvre une boîte de dialogue pour ajouter un nouveau produit
  void _addProductDialog() {
    final nameController = TextEditingController();
    final quantController = TextEditingController();
    final consoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter un produit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nom du produit")),
            TextField(controller: quantController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantité")),
            TextField(controller: consoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Consommé")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final quant = int.tryParse(quantController.text) ?? 0;
              final conso = int.tryParse(consoController.text) ?? 0;
              if (name.isNotEmpty) {
                _collection.add({
                  'produits': name,
                  'quantite': quant,
                  'consommer': conso,
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("La Boutique - Stock"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addProductDialog, tooltip: "Ajouter un produit"),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📦 Stock Boutique", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _collection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}"));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // Convertir en modèle et trier alphabétiquement
                  final rows = snapshot.data!.docs
                      .map((doc) => ShopStockModel.fromFirestore(doc))
                      .toList()
                    ..sort((a, b) => a.produits.toLowerCase().compareTo(b.produits.toLowerCase()));

                  // Créer les controllers
                  _quantiteControllers = rows.map((r) => TextEditingController(text: r.quantite.toString())).toList();
                  _consoControllers = rows.map((r) => TextEditingController(text: r.consommer.toString())).toList();

                  return Column(
                    children: [
                      // Header
                      Container(
                        color: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: const [
                            Expanded(flex: 2, child: Text('Produits', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Qté stock', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Conso', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Reste', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Cmd', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      // Lignes
                      Expanded(
                        child: ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final isEven = index % 2 == 0;
                            final reste = row.quantite - row.consommer;
                            final commande = reste < 10 ? "⚠️" : "✅";

                            return InkWell(
                              onLongPress: () => _confirmDelete(row),
                              child: Container(
                                color: isEven ? Colors.blue.shade50 : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: InkWell(
                                        onDoubleTap: () => modifierNomProduit(row),
                                        child: Text(row.produits, textAlign: TextAlign.center),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _quantiteControllers[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        onChanged: (value) => _updateCell(row, 'quantite', value),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _consoControllers[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        onChanged: (value) => _updateCell(row, 'consommer', value),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(reste.toString(), textAlign: TextAlign.center),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        commande,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: reste < 10 ? Colors.red : Colors.green,
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
          ],
        ),
      ),
    );
  }
}
