import 'package:flutter/material.dart';
// import 'package:gestion_fournitures/controllers/collaborator_controller.dart';
import 'package:gestion_fournitures/pages/edit_collaborator_page.dart';

class CollaboratorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  CollaboratorDetailsPage({super.key, required this.user, required this.docId});

  @override
  State<CollaboratorDetailsPage> createState() => _CollaboratorDetailsPageState();
}

class _CollaboratorDetailsPageState extends State<CollaboratorDetailsPage> {
  // late CollaboratorController collaboratorController = CollaboratorController(
  //   widget.user,
  //   widget.docId,
  // );

  @override
  void initState() {
    super.initState();
    collaboratorController.user = Map<String, dynamic>.from(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil ${widget.user['nickname'] ?? 'Utilisateur'}'),
        backgroundColor: Colors.blue,
        actions: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final deleted = await Navigator.push(context, MaterialPageRoute(
              builder: (context) => EditCollaboratorPage(user: widget.user, docId: widget.docId)
            ),
          );

          if (deleted == true) {
            Navigator.pop( context,true,
            ); // retourne directement à la liste des users
          }
        },
        child: Icon(Icons.edit),
      ),
    );
  }
}
