import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/controllers/history_controller.dart';
import 'package:gestion_fournitures/models/historyModel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoriesPage extends StatefulWidget {
  const HistoriesPage({super.key});

  @override
  State<HistoriesPage> createState() => _HistoriesPageState();
}

class _HistoriesPageState extends State<HistoriesPage> {
  final CollectionReference historiesRef =
      FirebaseFirestore.instance.collection('histories');
  final HistoryController historyController = HistoryController();

  String currentUserRole = '';
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        currentUserRole = doc.data()!['role'] ?? '';
      });
    }
  }

  bool get canDeleteHistory {
    return currentUserRole == 'Administrateur' ||
        currentUserRole == 'Directeur Général' ||
        currentUserRole == 'Directeur de Boutique';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des actions"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: historiesRef.orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("Aucune action enregistrée"),
              );
            }

            final histories = snapshot.data!.docs
                .map((doc) => HistoryModel.fromFirestore(doc))
                .toList();

            return Column(
              children: [
                // En-tête du tableau
                Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text("Prénom",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Action",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Produit",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 1,
                          child: Text("Reste",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Magasin",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Stand",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Date",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Liste des historiques
                Expanded(
                  child: ListView.builder(
                    itemCount: histories.length,
                    itemBuilder: (context, index) {
                      final h = histories[index];
                      final isEven = index % 2 == 0;

                      return Container(
                        color: isEven ? Colors.orange.shade50 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: GestureDetector(
                          onLongPress: canDeleteHistory
                              ? () => historyController.deleteHistory(
                                    context,
                                    h.id,
                                  )
                              : null, // 🔹 suppression autorisée uniquement pour admin et DG
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(h.user, textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text(h.action, textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text(h.product, textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text(h.reste.toString(), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text(h.shop, textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text(h.stand, textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text(
                                "${h.date!.day}/${h.date!.month}/${h.date!.year}",
                                textAlign: TextAlign.center,
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
