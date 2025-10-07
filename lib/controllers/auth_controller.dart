import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:gestion_fournitures/pages/edit_profile_page.dart';
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
  String nickname = '';
  String role = '';
  bool obscureText = true;

  String? selectedRole;
  List<String> selectedShops = [];
  List<String> selectedStands = [];

  List<String> roles = [
    'Administateur',
    'Directeur Général',
    'Directeur de Boutique',
    'Chef de Boutique',
    'Chef de Stand',
    'Collaborateur',
  ];
  List<String> shops = [];
  List<String> stands = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService authService = AuthService();

  /// Récupère la liste des boutiques et des stands depuis Firestore
  Future<void> fetchShopsAndStands() async {
    try {
      // Récupération des boutiques
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('boutiques')
          .get();
      shops = shopSnapshot.docs.map((doc) => doc['name'] as String).toList();

      // Récupération des stands
      final standSnapshot = await FirebaseFirestore.instance
          .collection('stands')
          .get();
      stands = standSnapshot.docs.map((doc) => doc['name'] as String).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur fetchShopsAndStands: $e');
    }
  }

  // Charger stands depuis Firestore
  Future<void> loadStands() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stands')
          .get();
      stands = snapshot.docs.map((doc) => doc['name'] as String).toList();
      notifyListeners();
    } catch (e) {
      print("Erreur loadStands: $e");
    }
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
