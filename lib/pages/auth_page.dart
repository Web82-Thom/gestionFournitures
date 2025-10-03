import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}
  AuthController authController = AuthController();

class _AuthPageState extends State<AuthPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(authController.isLogin ? 'Connexion' : 'Inscription')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: authController.formKey,
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
                  controller: authController.emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.contains('@') ? null : 'Email invalide',
                ),
                if (!authController.isLogin)
                  TextFormField(
                    controller: authController.nicknameController,
                    decoration: const InputDecoration(labelText: 'Surnom'),
                    validator: (value) =>
                        value!.isEmpty ? 'Champ requis' : null,
                  ),
                TextFormField(
                  controller: authController.passwordController,
                  obscureText: authController.obscureText,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                          authController.obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => authController.obscureText = !authController.obscureText),
                    ),
                  ),
                  validator: (value) => value!.length >= 6
                      ? null
                      : 'Minimum 6 caractères',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => authController.submit(context,),
                  child: Text(authController.isLogin ? 'Connexion' : 'Inscription'),
                ),
                if (authController.isLogin)
                  ElevatedButton(
                    onPressed: () => authController.resetPassword(context),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                TextButton(
                  onPressed: () => setState(() => authController.isLogin = !authController.isLogin),
                  child: Text(
                      authController.isLogin ? 'Créer un compte' : 'Se connecter'),
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
