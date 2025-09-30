import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryController extends ChangeNotifier {
  final currentUser = FirebaseAuth.instance.currentUser;
  String? _nickname;

  Future<String> getNickname() async {
    if (_nickname != null) return _nickname!;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 'inconnu';
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    _nickname = userDoc.exists ? (userDoc['nickname'] ?? currentUser.email ?? 'inconnu') : 'inconnu';
    return _nickname!;
  }
  /// Ajouter une entrée dans l'historique
  Future<void> addHistory({
    required String action,
    required String product,
    required int quantite,
    required int reste,
    required String shopName,
    String standName = '',
  }) async {
    final nickname = await getNickname();
    await FirebaseFirestore.instance.collection('histories').add({
      'user': nickname,
      'shopName': shopName,
      'standName': standName,
      'action': action,
      'product': product,
      'quantite': quantite,
      'reste': reste,
      'date': FieldValue.serverTimestamp(),
    });
  }
  /// Supprimer un historique avec confirmation
    Future<void> deleteHistory(BuildContext context, String historyId) async {
      final CollectionReference historyRef =FirebaseFirestore.instance.collection('histories');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Voulez-vous vraiment supprimer cet historique ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer"),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await historyRef.doc(historyId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Historique supprimé ✅")),
          );
        }
      }
    }
}
