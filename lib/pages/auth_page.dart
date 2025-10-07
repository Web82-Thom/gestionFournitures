import 'package:flutter/material.dart';
import 'package:gestion_fournitures/controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthController authController = AuthController();

  @override
  void initState() {
    super.initState();
    authController.fetchShopsAndStands();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(authController.isLogin ? 'Connexion' : 'Inscription'),
      ),
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
                  backgroundImage: AssetImage(
                    'assets/images/logoMyCookieFactory.jpg',
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: authController.emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 16),
                // Champ nickname obligatoire
                if (!authController.isLogin) ...[
                  TextFormField(
                    controller: authController.nicknameController,
                    decoration: const InputDecoration(labelText: 'Surnom'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
                  ),
                ],
                const SizedBox(height: 16),
                

                const SizedBox(height: 16),
                TextFormField(
                  controller: authController.passwordController,
                  obscureText: authController.obscureText,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        authController.obscureText
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => authController.obscureText =
                            !authController.obscureText,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value!.length >= 6 ? null : 'Minimum 6 caractères',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => authController.submit(context),
                  child: Text(
                    authController.isLogin ? 'Connexion' : 'Inscription',
                  ),
                ),
                if (authController.isLogin)
                  ElevatedButton(
                    onPressed: () => authController.resetPassword(context),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                TextButton(
                  onPressed: () => setState(
                    () => authController.isLogin = !authController.isLogin,
                  ),
                  child: Text(
                    authController.isLogin ? 'Créer un compte' : 'Se connecter',
                  ),
                ),
                const SizedBox(height: 80),
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                    'assets/images/logoMyCookieFactory.jpg',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//A implémenter dans le build() de AuthPage pour gérer les rôles et sélections apres le TextFormField du surname
// if (!authController.isLogin) ...[
  //   // Sélection du rôle
  //   DropdownButtonFormField<String>(
  //     value: authController.selectedRole,
  //     decoration: const InputDecoration(labelText: 'Rôle'),
  //     items: authController.roles.map((role) {
  //       return DropdownMenuItem(value: role, child: Text(role));
  //     }).toList(),
  //     onChanged: (value) {
  //       setState(() {
  //         authController.selectedRole = value!;
  //         // Reset des sélections de boutiques et stands à chaque changement de rôle
  //         authController.selectedShops = [];
  //         authController.selectedStands = [];
  //       });
  //     },
  //     validator: (value) =>
  //         value == null ? 'Choisissez un rôle' : null,
  //   ),

  //   // Directeur de boutique ou Chef de boutique → boutique obligatoire
  //   if (authController.selectedRole == 'Directeur de Boutique' ||
  //       authController.selectedRole == 'Chef de Boutique')
  //     DropdownButtonFormField<String>(
  //       value: authController.selectedShops.isNotEmpty
  //           ? authController.selectedShops.first
  //           : null,
  //       decoration: const InputDecoration(labelText: 'Boutique'),
  //       items: authController.shops.map((shop) {
  //         return DropdownMenuItem(value: shop, child: Text(shop));
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           authController.selectedShops = value != null
  //               ? [value]
  //               : [];
  //         });
  //       },
  //       validator: (value) => value == null
  //           ? 'Veuillez choisir une boutique'
  //           : null,
  //     ),

  //   // Chef de stand → stand obligatoire
  //   if (authController.selectedRole == 'Chef de Stand')
  //     DropdownButtonFormField<String>(
  //       value: authController.selectedStands.isNotEmpty
  //           ? authController.selectedStands.first
  //           : null,
  //       decoration: const InputDecoration(labelText: 'Stand'),
  //       items: authController.stands.map((stand) {
  //         return DropdownMenuItem(
  //           value: stand,
  //           child: Text(stand),
  //         );
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           authController.selectedStands = value != null
  //               ? [value]
  //               : [];
  //         });
  //       },
  //       validator: (value) =>
  //           value == null ? 'Veuillez choisir un stand' : null,
  //     ),

  //   // Collaborateur → choix libre, au moins boutique ou stand
  //   if (authController.selectedRole == 'Collaborateur') ...[
  //     DropdownButtonFormField<String>(
  //       value: authController.selectedShops.isNotEmpty
  //           ? authController.selectedShops.first
  //           : null,
  //       decoration: const InputDecoration(
  //         labelText: 'Boutique (optionnel)',
  //       ),
  //       items: authController.shops.map((shop) {
  //         return DropdownMenuItem(value: shop, child: Text(shop));
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           authController.selectedShops = value != null
  //               ? [value]
  //               : [];
  //         });
  //       },
  //     ),
  //     DropdownButtonFormField<String>(
  //       value: authController.selectedStands.isNotEmpty
  //           ? authController.selectedStands.first
  //           : null,
  //       decoration: const InputDecoration(
  //         labelText: 'Stand (optionnel)',
  //       ),
  //       items: authController.stands.map((stand) {
  //         return DropdownMenuItem(
  //           value: stand,
  //           child: Text(stand),
  //         );
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           authController.selectedStands = value != null
  //               ? [value]
  //               : [];
  //         });
  //       },
  //     ),
  //   ],
  // ],
