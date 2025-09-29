import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/stand_model.dart';
import 'turnover_table_page.dart';

class TurnoversPage extends StatelessWidget {
  const TurnoversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference standsCollection = FirebaseFirestore.instance.collection('stands');
    final CollectionReference boutiquesCollection = FirebaseFirestore.instance.collection('boutiques');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chiffres d'affaires"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<QuerySnapshot>(
          future: boutiquesCollection.get(), // 🔹 on lit les boutiques
          builder: (context, shopSnapshot) {
            if (shopSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!shopSnapshot.hasData || shopSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucune boutique disponible"));
            }

            // 🔹 On prend la première boutique trouvée (ex: Toulouse)
            final shopDoc = shopSnapshot.data!.docs.first;
            final shopId = shopDoc.id;
            final shopName = shopDoc['name'] ?? 'Boutique';

            return StreamBuilder<QuerySnapshot>(
              stream: standsCollection.snapshots(),
              builder: (context, standSnapshot) {
                if (standSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!standSnapshot.hasData || standSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucun stand disponible"));
                }

                // Convertir les stands
                final stands = standSnapshot.data!.docs
                    .map((doc) => StandModel.fromFirestore(doc))
                    .toList();

                // Ajouter la boutique comme premier élément
                final items = [
                  StandModel(id: shopId, name: shopName), // 🔹 bon nom ici
                  ...stands,
                ];

                return GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TurnoverTablePage(stand: item),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.green.shade200,
                        child: Center(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

