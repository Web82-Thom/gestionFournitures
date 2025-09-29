import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/stand_model.dart';
import 'turnover_table_page.dart';

class ChiffresAffairesPage extends StatelessWidget {
  const ChiffresAffairesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference standsCollection = FirebaseFirestore.instance.collection('stands');
    final CollectionReference shopCollection = FirebaseFirestore.instance.collection('boutiques');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chiffres d'affaires"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: standsCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucun stand disponible"));
            }

            // Transforme chaque document en StandModel
            final stands = snapshot.data!.docs
                .map((doc) => StandModel.fromFirestore(doc))
                .toList();

            // Ajouter un "boutique" en haut
            final items = [
              StandModel(id: shopCollection.id, name: shopCollection.id),
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
                    // Ouvre la page chiffre d'affaire du stand ou de la boutique
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TurnoverTablePage(stand: item),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.green.shade200,
                    child: Center(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
