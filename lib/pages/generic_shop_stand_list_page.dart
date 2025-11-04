import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/shop_stand_controller.dart';
import 'package:gestion_fournitures/pages/shop_or_stand_details_page.dart';
import 'package:gestion_fournitures/widgets/animated_cookie_background_mouve.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';

class GenericShopStandListPage extends StatelessWidget {
  final String title;
  final String collectionName;
  final bool isShop;

  const GenericShopStandListPage({
    super.key,
    required this.title,
    required this.collectionName,
    required this.isShop,
  });

  @override
  Widget build(BuildContext context) {
    final shopStandController = ShopStandController();
    final currentUser = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

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

        // Rôles autorisés à gérer les éléments
        final List<String> allowedRoles = [
          'Administrateur',
          'Directeur Général',
          'Directeur de Boutique',
          'Chef de Boutique',
          'Chef de Stand',
        ];
        final bool canManage = allowedRoles.contains(role);

        final collectionRef =
            FirebaseFirestore.instance.collection(collectionName);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            centerTitle: true,
            elevation: 3,
            shadowColor: Colors.black26,
            actions: [
              if (canManage)
                IconButton(
                  tooltip: isShop
                      ? "Ajouter une boutique"
                      : "Ajouter un stand",
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => isShop
                      ? shopStandController.addBoutiqueDialog(context)
                      : shopStandController.addStandDialog(context),
                ),
            ],
          ),
          body: Stack(
            children: [
              /// 🍪 Fond animé
              const IgnorePointer(
                child: AnimatedCookieBackgroundMouve(
                  cookieImage: 'assets/images/cookie.png',
                  count: 12,
                  size: 50,
                  speed: 0.0009,
                  opacity: 0.25,
                ),
              ),

              /// 📋 Liste principale
              Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<QuerySnapshot>(
                  stream: collectionRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          isShop
                              ? "Aucune boutique trouvée 🏬"
                              : "Aucun stand trouvé 🧁",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    final items = snapshot.data!.docs;

                    return GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final itemId = item.id;
                        final itemName =
                            (item['name'] ?? (isShop ? 'Boutique' : 'Stand'))
                                .toString();

                        return Hero(
                          tag: itemId,
                          child: BuildCardWidget(
                            icon: isShop
                                ? Icons.store_mall_directory_rounded
                                : Icons.storefront_rounded,
                            label: itemName,
                            page: ShopOrStandDetailsPage(
                              id: itemId,
                              name: itemName,
                              isShop: isShop,
                            ),
                            backgroundColor: isShop
                                ? Colors.green.shade200.withOpacity(0.8)
                                : Colors.blue.shade200.withOpacity(0.8),
                            iconColor: Colors.white,
                            fontSize: 14,
                            iconSize: 42,
                            padding: const EdgeInsets.all(8),
                            onLongPress: isAdmin
                                ? () => shopStandController.confirmDelete(
                                      context,
                                      itemId,
                                      isStand: !isShop,
                                    )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
