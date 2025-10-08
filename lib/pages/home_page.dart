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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  AuthController authController = AuthController();
  Future<void> get auth async => await authController.fetchUserData();
  String nickname = '';
  String role = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
    authController.fetchUserData();
  }

  Future<void> _loadNickname() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          nickname = doc.data()!['nickname'] ?? 'Utilisateur';
          role = doc.data()!['role'];
        });
      }
    } catch (e) {
      // Ignore les erreurs, on garde le nickname par défaut
    }
  }

  

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.account_circle),
            onPressed: () => authController.openOwnProfile(context),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => {
              FirebaseAuth.instance.signOut(),
              Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => AuthPage())),
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final data = await authController.fetchUserData();
          if (data != null && mounted) {
            setState(() {
              nickname = data['nickname'] ?? nickname;
              role = data['role'] ?? role;
            });
          }
        },
        child: GridView.count(
          crossAxisCount: 2,
          children: [
            if (isAdminOrManager) ...[
              Card(
                margin: EdgeInsets.all(20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TurnoversPage()),
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 70,
                          color: Colors.deepPurple,
                        ),
                        Text(
                          'Chiffres d\'affaires',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Card(
              margin: EdgeInsets.all(20),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StandsPage()),
                  );
                },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 70,
                        color: Colors.deepPurple,
                      ),
                      Text(
                        'Stock des stands',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.all(20),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ShopsListPage()),
                  );
                },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.store_mall_directory_rounded,
                        size: 70,
                        color: Colors.deepPurple,
                      ),
                      Text(
                        'Stock des boutiques',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.all(20),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoriesPage()),
                  );
                },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_edu_sharp,
                        size: 70,
                        color: Colors.deepPurple,
                      ),
                      Text('Historiques', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            if (isAdminOrManager) ...[
              Card(
                margin: EdgeInsets.all(20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollaboratorsPage(),
                      ),
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 70,
                          color: Colors.deepPurple,
                        ),
                        Text(
                          'Collaborateurs',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
