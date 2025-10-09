import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/stand_model.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';
import 'turnover_table_page.dart';

class TurnoversPage extends StatelessWidget {
  const TurnoversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference standsCollection =FirebaseFirestore.instance.collection('stands');
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
                )).toList();

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
                    childAspectRatio: 1,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    // Les premières sont des boutiques
                    final isShop = index < boutiques.length; 

                    return BuildCardWidget(
                      icon: isShop ? Icons.store_mall_directory_rounded : Icons.storefront_outlined,
                      label: item.name,
                      padding: const EdgeInsets.all(5),
                      page: TurnoverTablePage(
                        stand: item,
                        isShop: isShop,
                      ),
                      backgroundColor: isShop ? Colors.green.shade200 : Colors.blue.shade200,
                      iconSize: 50,
                      fontSize: 14,
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
