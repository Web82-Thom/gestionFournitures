import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // void openOwnProfile(BuildContext context) async {
  //   final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
  //   final userData = doc.data() as Map<String, dynamic>;

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EditProfilePage(
  //         user: userData,
  //         docId: currentUserId,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Cook'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () => (),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Center(
        child: Text('Bienvenue sur la page d\'accueil!'),
      ),
    );
  }
}

 