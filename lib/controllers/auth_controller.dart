import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/pages/home_page.dart';
import 'package:gestion_fournitures/services/auth_service.dart';

class AuthController extends  ChangeNotifier{
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();


  Future<void> submit(BuildContext context) async {
  if (!formKey.currentState!.validate()) return;

  try {
    if (isLogin) {
      await _authService.signIn(
        email:  emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } else {
      await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        nickname: nicknameController.text.trim(),
      );
    }

    // ✅ Vérifier si le widget est encore monté
    if (!context.mounted) return;

    // Redirection vers la page principale
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage()),
    );

  } catch (e) {
    if (!context.mounted) return; // ne pas afficher si widget démonté
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
                "Email de réinitialisation envoyé 📩, vérifier vos SPAM")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : ${e.message}")));
    }
  }
}