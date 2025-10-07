import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';
import 'package:gestion_fournitures/controllers/collaborator_controller.dart';
import 'package:gestion_fournitures/pages/collaborators_page.dart';

class EditCollaboratorPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  const EditCollaboratorPage({super.key, required this.user, required this.docId});

  @override
  State<EditCollaboratorPage> createState() => _EditCollaboratorPageState();
}
CollaboratorController collaboratorController = CollaboratorController({}, '');

class _EditCollaboratorPageState extends State<EditCollaboratorPage> {
  final AuthController authController = AuthController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;
  CollaboratorsPage userList = CollaboratorsPage();
  
  @override
  void initState() {
    super.initState();
    collaboratorController.nicknameController = TextEditingController(
      text: widget.user['nickname'] ?? '',
    );
    fetchRequests();
    _initData();
  }

  Future<void> _initData() async {
    await authController.fetchShopsAndStands();
    setState(() {
      authController.selectedRole = widget.user['role'] ?? '';
      authController.selectedShops = List<String>.from(
        widget.user['shopIds'] ?? [],
      );
      authController.selectedStands = List<String>.from(
        widget.user['standIds'] ?? [],
      );
      isLoading = false; // ✅ données prêtes
    });
  }

  void fetchRequests() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    setState(() {
      collaboratorController.requests = snapshot.exists ? [snapshot] : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = authController.selectedRole;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier le profil de ${widget.user['nickname']}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // 👈 attente chargement
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: collaboratorController.nicknameController,
                    decoration: const InputDecoration(labelText: 'Surnom'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: (role != null && role.isNotEmpty)
                        ? role
                        : null,
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
                    initialValue: authController.selectedShops.isNotEmpty
                        ? authController.selectedShops.first
                        : null,
                    decoration: const InputDecoration(labelText: 'Boutique'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'Aucune boutique',
                        child: Text('Aucune boutique'),
                      ),
                      ...authController.shops.map((shop) {
                        return DropdownMenuItem(value: shop, child: Text(shop));
                      }).toList(),
                    ],
                    onChanged: (value) => setState(() {
                      authController.selectedShops = value != null
                          ? [value]
                          : [];
                    }),
                  ),

                  // Dropdown stands
                  DropdownButtonFormField<String>(
                    initialValue: authController.selectedStands.isNotEmpty
                        ? authController.selectedStands.first
                        : null,
                    decoration: const InputDecoration(labelText: 'Stand'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'aucun stand',
                        child: Text('Aucun stand'),
                      ),
                      ...authController.stands.map((stand) {
                        return DropdownMenuItem(
                          value: stand,
                          child: Text(stand),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) => setState(() {
                      authController.selectedStands = value != null
                          ? [value]
                          : [];
                    }),
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer les modifications'),
                    onPressed: () async {
                      await collaboratorController.updateUserData(
                        userId: widget.docId,
                        newRole: authController.selectedRole,
                        newShop: authController.selectedShops,
                        newStand: authController.selectedStands,
                        context: context,
                      );
                      // Navigator.pop(context, true); // Retourne true si succès
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
