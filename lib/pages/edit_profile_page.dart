import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/auth_page.dart';

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
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.user['nickname'] ?? '',
    );
    if (widget.docId == currentUserId) fetchRequests();
  }

  // Future<void> _pickImage() async {
  //   final pickedFile = await ImagePicker().pickImage(
  //     source: ImageSource.gallery,
  //   );
  //   if (pickedFile != null) {
  //     setState(() => _selectedImage = File(pickedFile.path));
  //   }
  // }

  Future<void> _saveProfile() async {
    final updateData = {'nickname': _nicknameController.text};
    if (_selectedImage != null) {
      updateData['photoPath'] = _selectedImage!.path;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.docId)
        .update(updateData);
    Navigator.pop(context);
  }

  void fetchRequests() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      requests = snapshot.docs;
    });
  }

  Future<void> deleteFirebaseUser() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Ici tu peux gérer la ré-authentification (exemple avec email/password)
        throw Exception(
          'Ré-authentification requise pour supprimer le compte.',
        );
      } else {
        throw Exception(
          'Erreur lors de la suppression du compte : ${e.message}',
        );
      }
    }
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer votre profil ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Supprime le document Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .delete();

        // Supprime le compte Firebase Auth
        await FirebaseAuth.instance.currentUser!.delete();

        // Navigue vers la page Auth (connexion)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthPage()),
          (route) => false,
        );
      } catch (e) {
        // Gérer l'erreur (ex: re-authentification requise)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
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
              onPressed: _deleteProfile,
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
              ),
            ),
            if (isCurrentUser)
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Enregistrer les modifications'),
              ),
          ],
        ),
      ),
    );
  }
}
