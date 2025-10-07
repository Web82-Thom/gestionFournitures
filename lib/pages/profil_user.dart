import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/edit_user_page.dart';

class ProfilUser extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  const ProfilUser({super.key, required this.user, required this.docId});

  @override
  State<ProfilUser> createState() => _ProfilUserState();
}

class _ProfilUserState extends State<ProfilUser> {
  late Map<String, dynamic> user;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
  }

  Future<void> _openEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserPage(
          user: user,
          docId: widget.docId,
        ),
      ),
    );

    if (result == true) {
      // 🔁 Recharge les données du user depuis Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .get();
      if (doc.exists) {
        setState(() {
          user = doc.data()!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil ${user['nickname'] ?? 'Utilisateur'}'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          children: [
            Text('Rôle: ${user['role'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Travail dans la boutique:'),
            const SizedBox(height: 10),
            Text('${(user['shopIds'] as List<dynamic>?)?.join(', ') ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Travail au stand:'),
            const SizedBox(height: 10),
            Text('${(user['standIds'] as List<dynamic>?)?.join(', ') ?? 'N/A'}'),
            const SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditPage,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
