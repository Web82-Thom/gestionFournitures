import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/edit_collaborator_page.dart';
import 'package:gestion_fournitures/pages/edit_profile_page.dart';
import 'package:gestion_fournitures/pages/home_page.dart';
import 'package:gestion_fournitures/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  bool isLogin = true;
  bool get isLog => isLogin;

  void toggleMode() {
    isLogin = !isLogin;
    notifyListeners();
  }

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late TextEditingController nicknameController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  /// Récupère l'ID de l'utilisateur courant
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String nickname = '';
  String role = '';
  bool obscureText = true;

  String? selectedRole;
  List<String> selectedShops = [];
  List<String> selectedStands = [];
  Map<String, dynamic> user = {};
  List<String> roles = [
    'Administrateur',
    'Directeur Général',
    'Directeur de Boutique',
    'Chef de Boutique',
    'Chef de Stand',
    'Collaborateur',
  ];
  

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService authService = AuthService();
  
  /// Ouvre la page de modification du profil de l'utilisateur courant
  Future<void> openOwnProfile(BuildContext context) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun utilisateur connecté")),
      );
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil introuvable")));
      return;
    }

    final userData = doc.data();

    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la récupération des données"),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: userData, docId: currentUser!.uid),
      ),
    );
  }
  // Soumettre le formulaire de connexion ou d'inscription
  Future<void> submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    try {
      if (isLogin) {
        await authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          nickname: nicknameController.text.trim(),
        );
      }
      collaboratorController.fetchUserData();

      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
  // Réinitialiser le mot de passe
  Future<void> resetPassword(BuildContext context) async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre email")),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Email de réinitialisation envoyé 📩, vérifier vos SPAM",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : ${e.message}")));
    }
  }
}
