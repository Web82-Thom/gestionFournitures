import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/shop_stand_controller.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';
import 'package:gestion_fournitures/pages/shop_or_stand_details_page.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';

class ShopsListPage extends StatelessWidget {
  const ShopsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopRef = FirebaseFirestore.instance.collection('boutiques');
    final ShopStandController shopStandController = ShopStandController();
    final currentUser = FirebaseAuth.instance.currentUser;
    final authController = AuthController();

    // Rôle de l’utilisateur
    final String role = authController.role;
    final bool isAdmin = role == 'Administrateur';

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Aucun utilisateur connecté")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Les Boutiques"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => shopStandController.addBoutiqueDialog(context),
            icon: const Icon(Icons.add),
          ),
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
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                final shopId = shop.id;
                final shopName = (shop['name'] ?? 'Boutique').toString();

                return BuildCardWidget(
                  icon: Icons.store_mall_directory_rounded,
                  label: shopName,
                  page: ShopOrStandDetailsPage(
                    id: shopId,
                    name: shop['name'],
                    isShop: true,
                  ),
                  backgroundColor: Colors.blue.shade300,
                  iconColor: Colors.white,
                  fontSize: 14,
                  iconSize: 50,
                  onLongPress: isAdmin
                      ? () {
                          shopStandController.confirmDelete(
                            context,
                            shopId,
                            isStand: false,
                          );
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
