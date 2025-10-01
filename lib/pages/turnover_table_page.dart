import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  @override
  void initState() {
    super.initState();
    // Déterminer la référence Firestore selon isShop
    turnoverRef = widget.isShop
        ? FirebaseFirestore.instance
            .collection('boutiques')
            .doc(widget.stand.id)
            .collection('chiffreAffaire')
        : FirebaseFirestore.instance
            .collection('stands')
            .doc(widget.stand.id)
            .collection('chiffreAffaire');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chiffre d'affaire - ${widget.stand.name} ${widget.isShop ? '(Boutique)' : '(Stand)'}",
        ),
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
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: turnoverRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune donnée"));
          }

          // 🔹 On récupère les docs
          final docs = snapshot.data!.docs;

          // 🔹 On les parse en DateTime pour trier
          final parsed = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] ?? '';
            final recette = (data['recette'] ?? 0).toDouble();

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
              'parsedDate': parsedDate,
            };
          }).toList();

          // 🔹 Trier du plus récent au plus ancien
          parsed.sort((a, b) {
            final da = a['parsedDate'] as DateTime?;
            final db = b['parsedDate'] as DateTime?;
            if (da == null || db == null) return 0;
            return db.compareTo(da);
          });

          return Column(
            children: [
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
                  ],
                ),
              ),

              // 🔹 Tableau
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

                    // --- Ligne normale
                    final row = GestureDetector(
                      onDoubleTap: () => turnoverController.editTurnoverDialog(
                        context,
                        widget.stand.id,
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                        isStand: !widget.isShop,
                      ),
                      onLongPress: () => turnoverController.deleteTurnoverDialog(
                        context,
                        widget.stand.id,
                        doc.id,
                        isStand: !widget.isShop,
                      ),
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
                          ],
                        ),
                      ),
                    );
                    // --- Vérifier si c’est la dernière du mois
                    bool isLastOfMonth = false;
                    if (parsedDate != null) {
                      final m = parsedDate.month;
                      final y = parsedDate.year;

                      if (index == parsed.length - 1) {
                        isLastOfMonth = true;
                      } else {
                        final nextDate = parsed[index + 1]['parsedDate'] as DateTime?;
                        if (nextDate == null ||
                            nextDate.month != m ||
                            nextDate.year != y) {
                          isLastOfMonth = true;
                        }
                      }

                      if (isLastOfMonth) {
                        // Calculer total de ce mois
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Total ${turnoverController.monthName(m)} $y",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "$monthlyTotal €",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
