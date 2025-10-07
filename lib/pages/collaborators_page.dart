import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/pages/profil_user.dart';

class CollaboratorsPage extends StatelessWidget {
  CollaboratorsPage({super.key});
  final userList = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des utilisateurs'),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userList.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilUser(user: data, docId: user.id),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.brown,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      data['nickname'] ?? 'Sans surnom',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email : ${data['email'] ?? '-'}'),
                        Text('Rôle : ${data['role'] ?? '-'}'),
                        if (data['shopIds'] != null &&
                            (data['shopIds'] as List).isNotEmpty)
                          Text(
                            'Boutique : ${(data['shopIds'] as List).join(", ")}',
                          ),
                        if (data['standIds'] != null &&
                            (data['standIds'] as List).isNotEmpty)
                          Text(
                            'Stand : ${(data['standIds'] as List).join(", ")}',
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
