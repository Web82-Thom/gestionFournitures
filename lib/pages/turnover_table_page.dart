import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gestion_fournitures/controllers/pdf_controller.dart';
import 'package:gestion_fournitures/controllers/turnover_controller.dart';
import 'package:gestion_fournitures/models/stand_model.dart';
import 'package:gestion_fournitures/utils/dialog_helper.dart';
import 'package:gestion_fournitures/widgets/build_card_pdf_widget.dart';

class TurnoverTablePage extends StatefulWidget {
  final StandModel stand;
  final bool isShop;

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
  PdfController pdfController = PdfController();
  DialogHelper dialogHelper = DialogHelper();
  List<Reference> pdfFiles = [];

  @override
  void initState() {
    super.initState();
    turnoverRef = widget.isShop
        ? FirebaseFirestore.instance
              .collection('boutiques')
              .doc(widget.stand.id)
              .collection('chiffreAffaire')
        : FirebaseFirestore.instance
              .collection('stands')
              .doc(widget.stand.id)
              .collection('chiffreAffaire');

    _fetchCurrentUserRole();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    final files = await turnoverController.loadPdfFiles(
      isShop: widget.isShop,
      standId: widget.stand.id,
    );

    if (!mounted) return;
    setState(() {
      pdfFiles = files;
    });
  }

  Future<void> _fetchCurrentUserRole() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (snap.exists && mounted) setState(() => currentRole = snap['role']);
  }

  bool get canAdd => [
    'Administrateur',
    'Directeur Général',
    'Directeur de Boutique',
    'Chef de Stand',
  ].contains(currentRole);

  bool get canDelete => [
    'Administrateur',
    'Directeur Général',
    'Directeur de Boutique',
  ].contains(currentRole);

  bool get canEdit => canAdd;

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
          if (canAdd)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => turnoverController.addTurnoverDialog(
              context,
              widget.stand.id,
              isStand: !widget.isShop,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (scaffoldContext) {
            return StreamBuilder<QuerySnapshot>(
              stream: turnoverRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    currentRole == null) {
                  return Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                final parsed = snapshot.hasData
                    ? turnoverController.parseTurnoverData(snapshot.data!)
                    : [];

                if (parsed.isEmpty && pdfFiles.isEmpty) {
                  return const Center(child: Text("Aucune donnée"));
                }

                return Column(
                  children: [
                    // 🔹 En-tête
                    Container(
                      color: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                "Date",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                "Recette (€)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                "Créé par",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: parsed.length,
                        itemBuilder: (context, index) {
                          final item = parsed[index];
                          final doc = item['doc'] as DocumentSnapshot;
                          final dateStr = item['date'];
                          final recette = item['recette'] as double;
                          final parsedDate = item['parsedDate'] as DateTime?;
                          final createdBy = item['createdBy'];
                          final isEven = index % 2 == 0;

                          bool isHovered = false;
                          bool isSelected = false;

                          final row = StatefulBuilder(
                            builder: (context, setStateRow) {
                              return MouseRegion(
                                onEnter: (_) =>
                                    setStateRow(() => isHovered = true),
                                onExit: (_) =>
                                    setStateRow(() => isHovered = false),
                                child: GestureDetector(
                                  onTap: () => setStateRow(
                                    () => isSelected = !isSelected,
                                  ),
                                  child: Dismissible(
                                    key: ValueKey(doc.id),
                                    direction: DismissDirection.horizontal,
                                    background: canEdit
                                      ? Container(
                                          color: Colors.blue,
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Modifier",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                    secondaryBackground: canDelete
                                      ? Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Supprimer",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        if (canEdit) {
                                          turnoverController.editTurnoverDialog(
                                            context,
                                            widget.stand.id,
                                            doc.id,
                                            doc.data() as Map<String, dynamic>,
                                            isStand: !widget.isShop,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Accès refusé 🔒"),
                                            ),
                                          );
                                        }
                                        return false;
                                      }
                                      if (direction ==DismissDirection.endToStart) {
                                        if (canDelete) {
                                          turnoverController.deleteTurnoverDialog(
                                            context,
                                            widget.stand.id,
                                            doc.id,
                                            isStand: !widget.isShop,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Accès refusé 🔒"),
                                            ),
                                          );
                                        }
                                        return false;
                                      }
                                      return false;
                                    },
                                    child: Container(
                                      color: isHovered
                                        ? Colors.blue.shade100
                                        : isSelected
                                        ? Colors.blue.shade200
                                        : isEven
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Center(child: Text(dateStr)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text("$recette €"),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                createdBy,
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                          // 🔹 Total mensuel
                          if (parsedDate != null) {
                            final m = parsedDate.month;
                            final y = parsedDate.year;
                            bool isLastOfMonth =
                                index == parsed.length - 1 ||
                                (parsed[index + 1]['parsedDate'] as DateTime?)
                                        ?.month !=
                                    m ||
                                (parsed[index + 1]['parsedDate'] as DateTime?)
                                        ?.year !=
                                    y;

                            if (isLastOfMonth) {
                              double monthlyTotal = 0;
                              final monthData = parsed.where((d) {
                                final dDate = d['parsedDate'] as DateTime?;
                                return dDate != null &&
                                    dDate.month == m &&
                                    dDate.year == y;
                              }).toList();

                              if (monthData.isNotEmpty) {
                                for (var d in monthData) {
                                  monthlyTotal += d['recette'] as double;
                                }

                                return Column(
                                  children: [
                                    row,
                                    Dismissible(
                                      key: ValueKey("total_${m}_$y"),
                                      direction: DismissDirection.horizontal,
                                      background: Container(
                                        color: canDelete
                                            ? Colors.red
                                            : Colors.grey,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Supprimer toutes les entrées",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      secondaryBackground: Container(
                                        color: Colors.green,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: const [
                                            Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Générer PDF",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          if (!canDelete) {
                                            ScaffoldMessenger.of(
                                              scaffoldContext,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Accès refusé 🔒",
                                                ),
                                              ),
                                            );
                                            return false;
                                          }

                                          final confirm = await showDialog<bool>(
                                            context: scaffoldContext,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                "Confirmer la suppression",
                                              ),
                                              content: Text(
                                                "Voulez-vous supprimer toutes les entrées de ${turnoverController.monthName(m)} $y ?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                    Navigator.pop(scaffoldContext,false,),
                                                  child: const Text("Annuler"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        scaffoldContext,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    "Supprimer",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final idsToDelete = monthData
                                              .map((d) => d['doc'].id)
                                              .toList();
                                            Future.delayed(
                                              Duration.zero,
                                              () async {
                                                for (var id in idsToDelete) {
                                                  await turnoverRef
                                                    .doc(id)
                                                    .delete();
                                                }

                                                if (!context.mounted) return;

                                                ScaffoldMessenger.of(
                                                  scaffoldContext,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Toutes les entrées de ${turnoverController.monthName(m)} $y supprimées ✅",
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        } else if (direction ==
                                            DismissDirection.endToStart) {
                                          try {
                                            await pdfController
                                                .generateMonthlyPdf(
                                                  stand: widget.stand,
                                                  isShop: widget.isShop,
                                                  month: m,
                                                  year: y,
                                                  total: monthlyTotal,
                                                  data: monthData.cast<Map<String, dynamic>>(),
                                                );
                                            // 🔹 On recharge la liste après génération
                                            await _loadPdfFiles();

                                            if (!context.mounted) return false;
                                            ScaffoldMessenger.of(context,).showSnackBar(SnackBar(
                                                content: Text(
                                                  "PDF ${turnoverController.monthName(m)} $y généré ✅",
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              scaffoldContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Erreur lors de la génération du PDF : $e",
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          return false;
                                        }
                                        return false;
                                      },
                                      child: Container(
                                        color: Colors.green.shade200,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  "Total ${turnoverController.monthName(m)} $y",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  "$monthlyTotal €",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Expanded(
                                              flex: 2,
                                              child: SizedBox(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            }
                          }

                          return row;
                        },
                      ),
                    ),

                    // 🔹 PDFs générés
                    if (pdfFiles.isNotEmpty)
                      ...pdfFiles.map((f) => BuildCardPdfWidget(
                        fileRef: f,
                        parentContext: context,
                        pdfController: pdfController,
                        standId: widget.stand.id,
                        isShop: widget.isShop,
                        canDelete: canDelete,
                        reloadList: _loadPdfFiles,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
