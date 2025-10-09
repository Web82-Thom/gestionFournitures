import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/collaborator_controller.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  const EditProfilePage({super.key, required this.user, required this.docId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  List<DocumentSnapshot> requests = [];
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late TextEditingController _nicknameController;
  CollaboratorController collaboratorController = CollaboratorController({}, '');

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.user['nickname'] ?? '',
    );
    if (widget.docId == currentUserId) fetchRequests();
  }

  Future<void> _saveProfile() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) return;

    await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.docId)
      .update({'nickname': newNickname});
    // 🔹 Actualiser le texte de l'AppBar
    setState(() {
      widget.user['nickname'] = newNickname;
    });
  }

  void fetchRequests() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    setState(() {
      requests = snapshot.exists ? [snapshot] : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.docId == currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil de ${widget.user['nickname']}'),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => collaboratorController.deleteUser(
                userId: widget.docId,
                context: context,
              ),
              tooltip: 'Supprimer mon profil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nicknameController,
                readOnly: !isCurrentUser,
                decoration: InputDecoration(labelText: 'Surnom'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => {if (isCurrentUser) _saveProfile()},
              ),
            ),
            SizedBox(height: 20),
            Text('Email: ${widget.user['email'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text('Rôle: ${widget.user['role'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text(
              'Affiliations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Boutiques: ${(widget.user['shopIds'] as List<dynamic>?)?.join(', ') ?? 'Aucune'}',
            ),
            SizedBox(height: 20),
            Text(
              'Stands: ${(widget.user['standIds'] as List<dynamic>?)?.join(', ') ?? 'Aucun'}',
            ),
            SizedBox(height: 20),
            if (isCurrentUser)
            ElevatedButton(
              onPressed: () => {
                _saveProfile,
                Navigator.pop(context, true),
                ScaffoldMessenger.of(context,).showSnackBar(
                  SnackBar(content: Text('Profil mis à jour')),
                ),
              },
              child: Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }
}
