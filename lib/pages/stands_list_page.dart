import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/shop_stand_controller.dart';
import 'stand_details_page.dart';

class StandsPage extends StatelessWidget {
  const StandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final standsRef = FirebaseFirestore.instance.collection('stands');
    final ShopStandController shopStandController = ShopStandController();  

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stands"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(onPressed: () => shopStandController.addStandDialog(context),
          icon: const Icon(Icons.add))
        ],),
      body: StreamBuilder<QuerySnapshot>(
        stream: standsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun stand trouvé"));
          }

          final stands = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,          // 2 colonnes (mobile)
                childAspectRatio: 1.2,      // ajuster la taille des cartes
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stands.length,
              itemBuilder: (context, index) {
                final stand = stands[index];
                final standId = stand.id;
                final standName = (stand['name'] ?? 'Stand').toString();

                return InkWell(
                  onLongPress: () {
                    shopStandController.confirmDelete(context, standId, isStand: true);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StandDetailsPage(
                          standId: standId,
                          standName: standName,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade200, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        standName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
