import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_fournitures/controllers/turnover_controller.dart';
import 'package:gestion_fournitures/models/stand_model.dart';

class TurnoverTablePage extends StatefulWidget {
  final StandModel stand;
  final bool isShop; // savoir si on vient d'une boutique ou d'un stand

  const TurnoverTablePage({
    super.key,
    required this.stand,
    this.isShop = false,
  });

  @override
  State<TurnoverTablePage> createState() => _TurnoverTablePageState();
}

late CollectionReference turnoverRef;
final TurnoverController turnoverController = TurnoverController();

class _TurnoverTablePageState extends State<TurnoverTablePage> {
  String? currentRole;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // 🔹 Déterminer la collection Firestore selon isShop
    turnoverRef = widget.isShop
        ? FirebaseFirestore.instance
            .collection('boutiques')
            .doc(widget.stand.id)
            .collection('chiffreAffaire')
        : FirebaseFirestore.instance
            .collection('stands')
            .doc(widget.stand.id)
            .collection('chiffreAffaire');

    // 🔹 Récupérer le rôle de l'utilisateur connecté
    _fetchCurrentUserRole();
  }

  Future<void> _fetchCurrentUserRole() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snap.exists) {
      setState(() {
        currentRole = snap['role'];
      });
    }
  }

  bool get canAdd {
    // 🔹 Admin, DG, Directeur, Chef peuvent ajouter
    return [
      'Administrateur',
      'Directeur Général',
      'Directeur de Boutique',
      'Chef de Stand'
    ].contains(currentRole);
  }

  bool get canDelete {
    // 🔹 Admin, DG, Directeur peuvent supprimer
    return [
      'Administrateur',
      'Directeur Général',
      'Directeur de Boutique',
    ].contains(currentRole);
  }

  bool get canEdit {
    // 🔹 Même droits que ajout
    return canAdd;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chiffre d'affaire - ${widget.stand.name} ${widget.isShop ? '(Boutique)' : '(Stand)'}",
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                turnoverController.addTurnoverDialog(
                  context,
                  widget.stand.id,
                  isStand: !widget.isShop,
                );
              },
              tooltip: "Ajouter un chiffre d'affaire",
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: turnoverRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              currentRole == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune donnée"));
          }

          // 🔹 On récupère les docs
          final docs = snapshot.data!.docs;

          // 🔹 On parse et trie les dates
          final parsed = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] ?? '';
            final recette = (data['recette'] ?? 0).toDouble();
            final createdBy = data['createdBy'] ?? 'Inconnu';
            final parts = dateStr.split('/');
            DateTime? parsedDate;

            if (parts.length == 3) {
              final d = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              final y = int.tryParse(parts[2]);
              if (d != null && m != null && y != null) {
                parsedDate = DateTime(y, m, d);
              }
            }

            return {
              'doc': doc,
              'date': dateStr,
              'recette': recette,
              'createdBy': createdBy,
              'parsedDate': parsedDate,
            };
          }).toList();

          parsed.sort((a, b) {
            final da = a['parsedDate'] as DateTime?;
            final db = b['parsedDate'] as DateTime?;
            if (da == null || db == null) return 0;
            return db.compareTo(da);
          });

          return Column(
            children: [
              // 🔹 En-tête du tableau
              Container(
                color: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Date",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Recette (€)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Créé par",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 🔹 Tableau principal
              Expanded(
                child: ListView.builder(
                  itemCount: parsed.length,
                  itemBuilder: (_, index) {
                    final item = parsed[index];
                    final doc = item['doc'] as DocumentSnapshot;
                    final dateStr = item['date'] as String;
                    final recette = item['recette'] as double;
                    final parsedDate = item['parsedDate'] as DateTime?;
                    final isEven = index % 2 == 0;
                    // 🔹 Ligne individuelle
                    final row = Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.horizontal,
                      background: (canEdit)
                          ? Container(
                              color: Colors.blue,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Modifier", style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      secondaryBackground: (canDelete)
                          ? Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("Supprimer", style: TextStyle(color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete, color: Colors.white),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // ➡️ Glissement gauche → droite = ÉDITION
                          if (canEdit) {
                            turnoverController.editTurnoverDialog(
                              context,
                              widget.stand.id,
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                              isStand: !widget.isShop,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Accès refusé 🔒")),
                            );
                          }
                          return false; // On ne supprime pas
                        }

                        if (direction == DismissDirection.endToStart) {
                          // ⬅️ Glissement droite → gauche = SUPPRESSION
                          if (canDelete) {
                            turnoverController.deleteTurnoverDialog(
                              context,
                              widget.stand.id,
                              doc.id,
                              isStand: !widget.isShop,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Accès refusé 🔒")),
                            );
                          }
                          return false; // on gère manuellement
                        }

                        return false;
                      },
                      child: Container(
                        color: isEven ? Colors.blue.shade50 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(dateStr, textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "$recette €",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                (doc['createdBy'] ?? 'Inconnu'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );


                    // 🔹 Calcul du total mensuel
                    bool isLastOfMonth = false;
                    if (parsedDate != null) {
                      final m = parsedDate.month;
                      final y = parsedDate.year;

                      if (index == parsed.length - 1) {
                        isLastOfMonth = true;
                      } else {
                        final nextDate =
                            parsed[index + 1]['parsedDate'] as DateTime?;
                        if (nextDate == null ||
                            nextDate.month != m ||
                            nextDate.year != y) {
                              isLastOfMonth = true;
                            }
                      }

                      if (isLastOfMonth) {
                        double monthlyTotal = 0;
                        for (var d in parsed) {
                          final dDate = d['parsedDate'] as DateTime?;
                          if (dDate != null &&
                              dDate.month == m &&
                              dDate.year == y) {
                            monthlyTotal += d['recette'] as double;
                          }
                        }

                        return Column(
                          children: [
                            row,
                            Container(
                              color: Colors.green.shade200,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Total ${turnoverController.monthName(m)} $y",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "$monthlyTotal €",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Expanded(flex: 2, child: SizedBox()),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    }
                    return row;
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
