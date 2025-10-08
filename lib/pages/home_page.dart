import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/auth_page.dart';
import 'package:gestion_fournitures/pages/collaborators_page.dart';
import 'package:gestion_fournitures/pages/histories_page.dart';
import 'package:gestion_fournitures/pages/stands_list_page.dart';
import 'package:gestion_fournitures/pages/turnovers_page.dart';
import 'package:gestion_fournitures/pages/shops_list_page.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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

        // ✅ Déterminer si l’utilisateur est Admin / Manager
        final bool isAdminOrManager = [
          'Administrateur',
          'Directeur Général',
          'Directeur de Boutique',
          'Chef de Boutique',
          'Chef de Stand',
        ].contains(role);

        // Liste dynamique des cartes
        final List<Map<String, dynamic>> cards = [
          if (isAdminOrManager)
            {
              'icon': Icons.monetization_on_outlined,
              'label': 'Chiffres d\'affaires',
              'page': const TurnoversPage(),
            },
          {
            'icon': Icons.storefront_outlined,
            'label': 'Stock des stands',
            'page': const StandsPage(),
          },
          {
            'icon': Icons.store_mall_directory_rounded,
            'label': 'Stock des boutiques',
            'page': const ShopsListPage(),
          },
          {
            'icon': Icons.history_edu_sharp,
            'label': 'Historiques',
            'page': const HistoriesPage(),
          },
          if (isAdminOrManager)
            {
              'icon': Icons.admin_panel_settings,
              'label': 'Collaborateurs',
              'page': CollaboratorsPage(),
            },
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text('Bienvenue $nickname!'),
            backgroundColor: Colors.blue,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
              ),
            ],
          ),
          body: GridView.count(
            crossAxisCount: 2,
            children: cards.map((card) => BuildCardWidget(
              icon: card['icon'],
              label: card['label'],
              page: card['page'],
              backgroundColor: Colors.orangeAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              padding: const EdgeInsets.all(5)  ,
            )).toList(),
          ),
        );
      },
    );
  }
}
