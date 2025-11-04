import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';
import 'package:gestion_fournitures/pages/auth_page.dart';
import 'package:gestion_fournitures/pages/collaborators_page.dart';
import 'package:gestion_fournitures/pages/generic_shop_stand_list_page.dart';
import 'package:gestion_fournitures/pages/histories_page.dart';
import 'package:gestion_fournitures/pages/turnovers_page.dart';
import 'package:gestion_fournitures/widgets/animated_cookie_background_mouve.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';
import 'package:gestion_fournitures/widgets/build_section_title_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final authController = AuthController();

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
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final nickname = userData['nickname'] ?? 'Utilisateur';
        final role = userData['role'] ?? '';

        final bool isAdminOrManager = [
          'Administrateur',
          'Directeur Général',
          'Directeur de Boutique',
          'Chef de Boutique',
          'Chef de Stand',
        ].contains(role);

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Bienvenue $nickname!',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
            backgroundColor: colorScheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                color: colorScheme.onPrimary,
                onPressed: () => authController.openOwnProfile(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                color: colorScheme.onPrimary,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
              ),
            ],
          ),

          // 🍪 Fond animé avec cookies dispersés
          body: Stack(
            children: [
              const AnimatedCookieBackgroundMouve(
                cookieImage: 'assets/images/cookie.png',
                count: 10,
                size: 55,
                speed: 0.00095,
                opacity: 0.25,
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdminOrManager) BuildSectionTitleWidget(title:"📊 Gestion"),
                    if (isAdminOrManager)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        children: [
                          BuildCardWidget(
                            icon: Icons.monetization_on_outlined,
                            label: "Chiffres d'affaires",
                            page: const TurnoversPage(),
                            backgroundColor: colorScheme.secondaryContainer,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            padding: const EdgeInsets.all(5),
                          ),
                          BuildCardWidget(
                            icon: Icons.admin_panel_settings,
                            label: "Collaborateurs",
                            page: CollaboratorsPage(),
                            backgroundColor: colorScheme.secondaryContainer,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            padding: const EdgeInsets.all(5),
                          ),
                        ],
                      ),
                    const Divider(),
                    BuildSectionTitleWidget(title:"🏬 Les boutiques"),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      children: [
                        BuildCardWidget(
                          icon: Icons.store_mall_directory_rounded,
                          label: "Voir les boutiques",
                          page: GenericShopStandListPage(
                            title: "Les Boutiques",
                            collectionName: "boutiques",
                            isShop: true,
                          ),
                          backgroundColor: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          padding: const EdgeInsets.all(5),
                        ),
                        BuildCardWidget(
                          icon: Icons.history_edu_sharp,
                          label: "Historiques",
                          page: const HistoriesPage(),
                          backgroundColor: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          padding: const EdgeInsets.all(5),
                        ),
                      ],
                    ),

                    const Divider(),

                    BuildSectionTitleWidget(title:"🧁 Les stands"),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      children: [
                        BuildCardWidget(
                          icon: Icons.storefront_outlined,
                          label: "Voir les stands",
                          page: GenericShopStandListPage(
                            title: "Les Stands",
                            collectionName: "stands",
                            isShop: false,
                          ),
                          backgroundColor: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          padding: const EdgeInsets.all(5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




