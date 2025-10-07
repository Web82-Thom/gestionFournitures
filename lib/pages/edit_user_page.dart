import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';
import 'package:gestion_fournitures/pages/auth_page.dart';
import 'package:gestion_fournitures/pages/collaborators_page.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  const EditUserPage({super.key, required this.user, required this.docId});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final AuthController authController = AuthController();
  late TextEditingController _nicknameController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true; // 👈 état de chargement
  CollaboratorsPage userList = CollaboratorsPage();
  List<DocumentSnapshot> requests = [];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.user['nickname'] ?? '',
    );
    userList.userList.get();
    fetchRequests();
    _initData();
  }

  Future<void> _initData() async {
    await authController.fetchShopsAndStands();
    
    setState(() {
      authController.selectedRole = widget.user['role'] ?? '';
      authController.selectedShops =
          List<String>.from(widget.user['shopIds'] ?? []);
      authController.selectedStands =
          List<String>.from(widget.user['standIds'] ?? []);
      isLoading = false; // ✅ données prêtes
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
  Future<void> updateUserData({
    required String userId,
    String? newNickname,
    String? newRole,
    List<String>? newShop,
    List<String>? newStand,
    required BuildContext context,
  }) async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) return;
    try {
      if (newRole != 'Directeur Général' &&
          (newShop == null || newShop.isEmpty) &&
          (newStand == null || newStand.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner au moins une boutique ou un stand.'),
          ),
        );
        return;
      }

      final Map<String, dynamic> updateData = {};
      if (newNickname.isNotEmpty) updateData['nickname'] = newNickname;
      if (newRole != null && newRole.isNotEmpty) updateData['role'] = newRole;
      if (newShop != null && newShop.isNotEmpty) updateData['shopIds'] = newShop;
      if (newStand != null && newStand.isNotEmpty) updateData['standIds'] = newStand;

      await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);
      setState(() {
        widget.user['nickname'] = newNickname;
        widget.user['role'] = newRole;
        widget.user['shopIds'] = newShop;
        widget.user['standIds'] = newStand;
      });

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

  Future<void> _deleteProfile() async {
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

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.docId).delete();

        if (widget.docId == currentUserId) {
          await FirebaseAuth.instance.currentUser!.delete();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthPage()),
          );
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = authController.selectedRole;
    final shop = authController.selectedShops;
    final stand = authController.selectedStands;

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier le profil de ${widget.user['nickname']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteProfile,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 👈 attente chargement
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: 'Surnom'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: (role != null && role.isNotEmpty) ? role : null,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: authController.roles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        authController.selectedRole = value!;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Choisissez un rôle' : null,
                  ),
                  const SizedBox(height: 20),

                  // Dropdown boutiques
                  DropdownButtonFormField<String>(
                    initialValue: (shop.isNotEmpty) ? shop.first : null,
                    decoration: const InputDecoration(labelText: 'Boutique'),
                    items: authController.shops.map((shop) {
                      return DropdownMenuItem(value: shop, child: Text(shop));
                    }).toList(),
                    onChanged: (value) => setState(() {
                      authController.selectedShops =
                          value != null ? [value] : [];
                    }),
                  ),

                  // Dropdown stands
                  DropdownButtonFormField<String>(
                    value: (stand.isNotEmpty) ? stand.first : null,
                    decoration: const InputDecoration(labelText: 'Stand'),
                    items: authController.stands.map((stand) {
                      return DropdownMenuItem(value: stand, child: Text(stand));
                    }).toList(),
                    onChanged: (value) => setState(() {
                      authController.selectedStands =
                          value != null ? [value] : [];
                    }),
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer les modifications'),
                    onPressed: () => updateUserData(
                      userId: widget.docId,
                      newRole: authController.selectedRole,
                      newShop: authController.selectedShops,
                      newStand: authController.selectedStands,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
