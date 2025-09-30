import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Connexion
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Inscription avec nickname
  Future<User?> signUp({
    required String email,
    required String password,
    String? nickname,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;

      if (user != null) {
        // On crée le document Firestore pour l'utilisateur
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'nickname': nickname ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Stream pour écouter l'état de l'utilisateur
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
