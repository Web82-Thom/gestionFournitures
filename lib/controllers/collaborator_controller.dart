import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/auth_page.dart';
import 'package:gestion_fournitures/pages/collaborators_page.dart';
import 'package:gestion_fournitures/pages/edit_collaborator_page.dart';

class CollaboratorController extends ChangeNotifier{
  late Map<String, dynamic> user;
  final String docId;
  final formKey = GlobalKey<FormState>();
  TextEditingController nicknameController = TextEditingController();
  List<DocumentSnapshot> requests = [];
  CollaboratorController(this.user, this.docId);
  String nickname = '';
  String role = '';

  String nicknameLoad = '';
  String roleLoad = '';
  Future<void> loadNickname() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        
          nicknameLoad = doc.data()!['nickname'] ?? 'Utilisateur';
          roleLoad = doc.data()!['role'];
          notifyListeners(); // 🔁 utile si tu utilises Provider
      }
    } catch (e) {
      // Ignore les erreurs, on garde le nickname par défaut
    }
  }
  /// Récupère les données de l'utilisateur courant depuis Firestore
  Future<Map<String, dynamic>?> fetchUserData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      nickname = data['nickname'] ?? 'Utilisateur';
      role = data['role'] ?? '';
      notifyListeners(); // 🔁 utile si tu utilises Provider
      return data;
    }
  } catch (e) {
    debugPrint('Erreur fetchUserData: $e');
  }
  return null;
}
  
  Future<void> openEditPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCollaboratorPage(
          user: user,
          docId: docId,
        ),
      ),
    );

    if (result == true) {
      // 🔁 Recharge les données du user depuis Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();
      if (doc.exists) {
        user = doc.data()!;
        notifyListeners();
      }
    }
  }

  Future<void> updateUserData({
    required String userId,
    String? newNickname,
    String? newRole,
    List<String>? newShop,
    List<String>? newStand,
    required BuildContext context,
  }) async {
    final newNickname = nicknameController.text.trim();
    if (newNickname.isEmpty) return;

    try {

      final Map<String, dynamic> updateData = {};
      if (newNickname.isNotEmpty) updateData['nickname'] = newNickname;
      if (newRole != null && newRole.isNotEmpty) updateData['role'] = newRole;
      if (newShop != null && newShop.isNotEmpty) updateData['shopIds'] = newShop;
      if (newStand != null && newStand.isNotEmpty) updateData['standIds'] = newStand;

      await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);
      
        user['nickname'] = newNickname;
        user['role'] = newRole;
        user['shopIds'] = newShop  ?? ['Aucune boutique'];
        user['standIds'] = newStand ?? ['Aucun stand'];
        notifyListeners();      

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès ✅')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Erreur updateUserData: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
      );
    }
  }

  Future<void> deleteUser({
  required String userId, // UID du user à supprimer
  required BuildContext context,
}) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer la suppression'),
      content: const Text(
          'Voulez-vous vraiment supprimer ce profil ? Cette action est irréversible.'),
      actions: [
        TextButton(
          child: const Text('Annuler'),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    // 1️⃣ Supprimer le document Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();

    // 2️⃣ Supprimer l’utilisateur Auth seulement si c’est le compte courant
    if (FirebaseAuth.instance.currentUser?.uid == userId) {
      await FirebaseAuth.instance.currentUser!.delete();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé avec succès ✅')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CollaboratorsPage()),
      ); // retour à la liste des utilisateurs
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la suppression : $e')),
    );
  }
}

}