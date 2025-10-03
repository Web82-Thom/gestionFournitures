import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/shop_stand_controller.dart';
import 'package:gestion_fournitures/pages/shop_details_page.dart';

class ShopsListPage extends StatelessWidget {
  const ShopsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopRef = FirebaseFirestore.instance.collection('boutiques');
    final ShopStandController shopStandController = ShopStandController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Les Boutiques"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(onPressed: () => shopStandController.addBoutiqueDialog(context),
          icon: Icon(Icons.add))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: shopRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune boutique trouvée"));
          }

          final shops = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,          // 2 colonnes (mobile)
                childAspectRatio: 1.2,      // ajuster la taille des cartes
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                final shopId = shop.id;
                final shopName = (shop['name'] ?? 'Boutique').toString();

                return InkWell(
                  onLongPress: () {
                    shopStandController.confirmDelete(context, shopId, isStand: false);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LaBoutiquePage(
                          shopId: shopId,
                          shopName: shopName,
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
                        shopName,
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
