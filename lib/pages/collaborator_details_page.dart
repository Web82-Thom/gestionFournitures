import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/edit_collaborator_page.dart';
import 'package:gestion_fournitures/controllers/collaborator_controller.dart';

class CollaboratorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  const CollaboratorDetailsPage({super.key, required this.user, required this.docId});

  @override
  State<CollaboratorDetailsPage> createState() => _CollaboratorDetailsPageState();
}

class _CollaboratorDetailsPageState extends State<CollaboratorDetailsPage> {
  final CollaboratorController collaboratorController = CollaboratorController({}, '');
  Map<String, dynamic>? currentUserData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    collaboratorController.user = Map<String, dynamic>.from(widget.user);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final data = await collaboratorController.fetchUserData();
    setState(() {
      currentUserData = data;
      isLoading = false;
    });
  }

  // 🔹 Vérifie si l'utilisateur courant peut supprimer la cible
  bool canDeleteUser(Map<String, dynamic> currentUser, Map<String, dynamic> targetUser) {
    final currentRole = currentUser['role'] ?? '';
    final targetRole = targetUser['role'] ?? '';

    if (currentRole == 'Administrateur') {
      return true; // Admin peut tout supprimer
    }

    if (currentRole == 'Directeur Général') {
      return targetRole != 'Administrateur' && targetRole != 'Directeur Général';
    }

    if (currentRole == 'Directeur de Boutique') {
      return targetRole == 'Chef de Boutique' ||
          targetRole == 'Chef de Stand' ||
          targetRole == 'Collaborateur';
    }

    return false; // Autres rôles ne peuvent rien supprimer
  }

  // 🔹 Vérifie si l'utilisateur courant peut modifier la cible
  bool canEditUser(Map<String, dynamic> currentUser, Map<String, dynamic> targetUser) {
    final currentRole = currentUser['role'] ?? '';
    final targetRole = targetUser['role'] ?? '';

    if (currentRole == 'Administrateur') {
      return true; // Admin peut tout modifier
    }

    if (currentRole == 'Directeur Général') {
      return targetRole != 'Administrateur' && targetRole != 'Directeur Général';
    }

    if (currentRole == 'Directeur de Boutique') {
      return targetRole == 'Chef de Boutique' ||
          targetRole == 'Chef de Stand' ||
          targetRole == 'Collaborateur';
    }

    return false; // Autres rôles ne peuvent rien modifier
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canDelete = canDeleteUser(currentUserData!, widget.user);
    final canEdit = canEditUser(currentUserData!, widget.user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil ${widget.user['nickname'] ?? 'Utilisateur'}'),
        backgroundColor: Colors.blue,
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => collaboratorController.deleteUser(
                userId: widget.docId,
                context: context,
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Text('Rôle: ${widget.user['role'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Travail dans la boutique:'),
            const SizedBox(height: 10),
            Text(
              (widget.user['shopIds'] as List<dynamic>?)?.join(', ') ?? 'N/A',
            ),
            const SizedBox(height: 10),
            Text('Travail au stand:'),
            const SizedBox(height: 10),
            Text(
              (widget.user['standIds'] as List<dynamic>?)?.join(', ') ?? 'N/A',
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

      // ✏️ Bouton de modification visible seulement si autorisé
      floatingActionButton: canEdit
          ? FloatingActionButton(
              child: const Icon(Icons.edit),
              onPressed: () async {
                final deleted = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCollaboratorPage(
                      user: widget.user,
                      docId: widget.docId,
                    ),
                  ),
                );
                if (deleted == true) {
                  Navigator.pop(context, true);
                }
              },
            )
          : null,
    );
  }
}
