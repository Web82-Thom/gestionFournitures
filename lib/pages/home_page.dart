import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';
import 'package:gestion_fournitures/pages/auth_page.dart';
import 'package:gestion_fournitures/pages/collaborators_page.dart';
import 'package:gestion_fournitures/pages/histories_page.dart';
import 'package:gestion_fournitures/pages/stands_list_page.dart';
import 'package:gestion_fournitures/pages/turnovers_page.dart';
import 'package:gestion_fournitures/pages/shops_list_page.dart';

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
        // 🕐 Si les données sont encore en chargement
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Si on a les données de l’utilisateur
        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        final nickname = userData?['nickname'] ?? 'Utilisateur';
        final role = userData?['role'] ?? '';

        final bool isAdminOrManager = [
          'Administrateur',
          'Directeur Général',
          'Directeur de Boutique',
          'Chef de Boutique',
          'Chef de Stand',
        ].contains(role);

        return Scaffold(
          appBar: AppBar(
            title: Text('Bienvenue $nickname!'),
            backgroundColor: Colors.blue,
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => authController.openOwnProfile(context),
              ),
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
            children: [
              if (isAdminOrManager) ...[
                _buildCard(
                  context,
                  icon: Icons.monetization_on_outlined,
                  label: 'Chiffres d\'affaires',
                  page: const TurnoversPage(),
                ),
              ],
              _buildCard(
                context,
                icon: Icons.storefront_outlined,
                label: 'Stock des stands',
                page: const StandsPage(),
              ),
              _buildCard(
                context,
                icon: Icons.store_mall_directory_rounded,
                label: 'Stock des boutiques',
                page: const ShopsListPage(),
              ),
              _buildCard(
                context,
                icon: Icons.history_edu_sharp,
                label: 'Historiques',
                page: const HistoriesPage(),
              ),
              if (isAdminOrManager) ...[
                _buildCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  label: 'Collaborateurs',
                  page: CollaboratorsPage(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context,
    {required IconData icon, required String label, required Widget page}) {
  return Card(
    margin: const EdgeInsets.all(20),
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // 👈 ajoute de l’espace interne
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 👈 centre verticalement
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Icon(icon, size: 50, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // 👈 évite débordement texte
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
