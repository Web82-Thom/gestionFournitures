import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/shop_stand_controller.dart';
import 'package:gestion_fournitures/pages/shop_or_stand_details_page.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';

class StandsListPage extends StatelessWidget {
  const StandsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final standsRef = FirebaseFirestore.instance.collection('stands');
    final currentUser = FirebaseAuth.instance.currentUser;
    final ShopStandController shopStandController = ShopStandController();

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Aucun utilisateur connecté")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final String role = userData?['role'] ?? '';
        final bool isAdmin = role == 'Administrateur';

        // Rôles autorisés pour voir le bouton
        final List<String> allowedRoles = [
          'Administrateur',
          'Directeur Général',
          'Directeur de Boutique',
          'Chef de Boutique',
          'Chef de Stand',
        ];

        final bool canSeeButton = allowedRoles.contains(role);

        return Scaffold(
          appBar: AppBar(
            title: const Text("Stands"),
            backgroundColor: Colors.blue,
            actions: [
              if (canSeeButton)
                IconButton(
                  onPressed: () => shopStandController.addStandDialog(context),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
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
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: stands.length,
                  itemBuilder: (context, index) {
                    final stand = stands[index];
                    final standId = stand.id;
                    final standName = (stand['name'] ?? 'Stand').toString();

                    return BuildCardWidget(
                      icon: Icons.storefront_outlined,
                      label: standName,
                      page: ShopOrStandDetailsPage(
                        id: standId,
                        name: stand['name'],
                        isShop: false,
                      ),
                      backgroundColor: Colors.blue.shade300,
                      fontSize: 14,
                      iconSize: 40,
                      onLongPress: isAdmin
                          ? () async {
                              await shopStandController.confirmDelete(
                                context,
                                standId,
                                isStand: true,
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
      },
    );
  }
}
