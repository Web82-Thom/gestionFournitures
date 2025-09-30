import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/stand_model.dart';
import 'turnover_table_page.dart';

class TurnoversPage extends StatelessWidget {
  const TurnoversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference standsCollection =
        FirebaseFirestore.instance.collection('stands');
    final CollectionReference boutiquesCollection =
        FirebaseFirestore.instance.collection('boutiques');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chiffres d'affaires"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<QuerySnapshot>(
          future: boutiquesCollection.get(),
          builder: (context, boutiqueSnapshot) {
            if (boutiqueSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!boutiqueSnapshot.hasData || boutiqueSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucune boutique disponible"));
            }

            // Liste des boutiques
            final boutiques = boutiqueSnapshot.data!.docs
                .map((doc) => StandModel(
                      id: doc.id,
                      name: doc['name'] ?? 'Boutique',
                    ))
                .toList();

            return StreamBuilder<QuerySnapshot>(
              stream: standsCollection.snapshots(),
              builder: (context, standSnapshot) {
                if (standSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!standSnapshot.hasData || standSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucun stand disponible"));
                }

                // Liste des stands
                final stands = standSnapshot.data!.docs
                    .map((doc) => StandModel.fromFirestore(doc))
                    .toList();

                // On combine boutiques et stands
                final items = [
                  ...boutiques,
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
                    final isShop = index < boutiques.length; // 🔹 Les premières sont des boutiques

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TurnoverTablePage(
                              stand: item,
                              isShop: isShop,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isShop ? Colors.green.shade200 : Colors.blue.shade200,
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
