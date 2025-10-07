import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final nicknameController = TextEditingController();
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

  // Charger boutiques depuis Firestore
  Future<void> loadShops() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('boutiques')
          .get();
      shops = snapshot.docs.map((doc) => doc['name'] as String).toList();
      notifyListeners();
    } catch (e) {
      print("Erreur loadShops: $e");
    }
  }

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

  Future<void> submit(BuildContext context) async {
  if (!formKey.currentState!.validate()) return;

  // Validation spéciale selon le rôle
  if ((selectedRole == 'Directeur de Boutique' || selectedRole == 'Chef de Boutique') &&
    selectedShops.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Veuillez choisir une boutique")),
  );
  return;
}

  if (selectedRole == 'Chef de Stand' && selectedStands.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Veuillez choisir un stand")),
  );
  return;
}

  if (selectedRole == 'Collaborateur' && selectedShops.isEmpty && selectedStands.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Un collaborateur doit choisir au moins une boutique ou un stand")),
  );
  return;
}

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
        // role: selectedRole!,
        // shop: selectedShops,
        // stand: selectedStands,
      );
    }

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $e')),
    );
  }
}



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
