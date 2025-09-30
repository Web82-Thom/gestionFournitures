import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_fournitures/services/auth_service.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLogin = true;
  bool _obscureText = true;

  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre email")),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
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

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    if (_isLogin) {
      await _authService.signIn(
        email:  _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
      );
    }

    // ✅ Vérifier si le widget est encore monté
    if (!mounted) return;

    // Redirection vers la page principale
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage()),
    );

  } catch (e) {
    if (!mounted) return; // ne pas afficher si widget démonté
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Connexion' : 'Inscription')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      AssetImage('assets/images/logoMyCookieFactory.jpg'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.contains('@') ? null : 'Email invalide',
                ),
                if (!_isLogin)
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: 'Surnom'),
                    validator: (value) =>
                        value!.isEmpty ? 'Champ requis' : null,
                  ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  validator: (value) => value!.length >= 6
                      ? null
                      : 'Minimum 6 caractères',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Connexion' : 'Inscription'),
                ),
                if (_isLogin)
                  ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                      _isLogin ? 'Créer un compte' : 'Se connecter'),
                ),
                const SizedBox(height: 80),
                const CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      AssetImage('assets/images/logoMyCookieFactory.jpg'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
