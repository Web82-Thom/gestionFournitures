import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/shop_stock_model.dart';
import 'dart:async';

class LaBoutiquePage extends StatefulWidget {
  const LaBoutiquePage({super.key});

  @override
  State<LaBoutiquePage> createState() => _LaBoutiquePageState();
}

class _LaBoutiquePageState extends State<LaBoutiquePage> {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'boutique',
  );

  List<ShopStockModel> _rows = [];
  List<TextEditingController> _quantiteControllers = [];
  List<TextEditingController> _consoControllers = [];

  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = _collection.snapshots().listen((snapshot) {
      if (!mounted) return;

      final newRows = snapshot.docs
          .map((doc) => ShopStockModel.fromFirestore(doc))
          .toList();

      // Mettre à jour les controllers existants sans les recréer
      for (int i = 0; i < newRows.length; i++) {
        if (i < _quantiteControllers.length) {
          _quantiteControllers[i].text = newRows[i].quantite.toString();
          _consoControllers[i].text = newRows[i].consommer.toString();
        } else {
          _quantiteControllers.add(
            TextEditingController(text: newRows[i].quantite.toString()),
          );
          _consoControllers.add(
            TextEditingController(text: newRows[i].consommer.toString()),
          );
        }
      }

      _rows = newRows;
      setState(() {});
    });
  }

  void _confirmDelete(int index) async {
    final row = _rows[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Voulez-vous vraiment supprimer le produit '${row.produits}' ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _collection.doc(row.id).delete();
    }
  }

  void _updateCell(int index, String key, String value) {
    int parsedValue = int.tryParse(value) ?? 0;

    if (parsedValue < 0) parsedValue = 0;
    if (key == 'consommer' && parsedValue > _rows[index].quantite) {
      parsedValue = _rows[index].quantite;
    }

    final docId = _rows[index].id;
    _collection.doc(docId).update({key: parsedValue});
  }

  @override
  void dispose() {
    _subscription.cancel();
    _quantiteControllers.forEach((c) => c.dispose());
    _consoControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  /// Ouvre une boîte de dialogue pour ajouter un nouveau produit
  void _addProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantController = TextEditingController();
    final TextEditingController consoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter un produit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom du produit"),
              ),
              TextField(
                controller: quantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantité"),
              ),
              TextField(
                controller: consoController,
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
              onPressed: () {
                String name = nameController.text.trim();
                int quant = int.tryParse(quantController.text) ?? 0;
                int conso = int.tryParse(consoController.text) ?? 0;
                if (name.isNotEmpty) {
                  _collection.add({
                    "produits": name,
                    "quantite": quant,
                    "consommer": conso,
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("La Boutique - Stock"),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📦 Stock Boutique",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _rows.isEmpty
                  ? const Center(child: Text("Aucun produit"))
                  : Column(
                      children: [
                        // Header
                        Container(
                          color: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Prdt',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
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
                                flex: 2,
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
                                flex: 1,
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
                                flex: 1,
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
                        // Lignes
                        Expanded(
                          child: ListView.builder(
                            itemCount: _rows.length,

                            // Remplace l'itemBuilder dans le ListView.builder :
                            itemBuilder: (context, index) {
                              final row = _rows[index];
                              final isEven = index % 2 == 0;

                              return InkWell(
                                onLongPress: () => _confirmDelete(index),
                                child: Container(
                                  color: isEven
                                      ? Colors.blue.shade50
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          row.produits,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller:
                                              _quantiteControllers[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          onChanged: (value) => _updateCell(
                                            index,
                                            'quantite',
                                            value,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _consoControllers[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          onChanged: (value) => _updateCell(
                                            index,
                                            'consommer',
                                            value,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          row.reste.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          row.commande,
                                          textAlign: TextAlign.center,
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
