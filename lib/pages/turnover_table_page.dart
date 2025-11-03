import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:gestion_fournitures/controllers/pdf_controller.dart';
import 'package:gestion_fournitures/controllers/turnover_controller.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';
import 'package:gestion_fournitures/utils/dialog_helper.dart';
import 'package:gestion_fournitures/widgets/build_card_pdf_widget.dart';

class TurnoverTablePage extends StatefulWidget {
  final ShopStandModel stand;
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
  final pdfController = PdfController();
  final dialogHelper = DialogHelper();
  List<File> pdfFiles = [];
  bool showPdfList = false; // ✅ contrôle de la visibilité de la liste PDF

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
    final files = await pdfController.loadLocalPdfFiles();
    // ✅ Filtrer selon le nom du stand/boutique sélectionné
    final filtered = files.where((file) {
      final name = p.basename(file.path).toLowerCase();
      final standName = widget.stand.name.toLowerCase();
      // Garde uniquement les PDFs qui contiennent le nom du stand ou boutique
      return name.contains(standName);
    }).toList();

    if (!mounted) return;
    setState(() => pdfFiles = filtered);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chiffre d'affaire - ${widget.stand.name} ${widget.isShop ? '(Boutique)' : '(Stand)'}",
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        actions: [
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Ajouter une recette",
              onPressed: () => turnoverController.addTurnoverDialog(
                context,
                widget.stand.id,
                isStand: !widget.isShop,
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // === CONTENU PRINCIPAL ===
            Column(
              children: [
                _buildHeaderRow(colorScheme),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: turnoverRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || currentRole == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final parsed = snapshot.hasData
                        ? turnoverController.parseTurnoverData(snapshot.data!)
                        : [];

                      if (parsed.isEmpty && pdfFiles.isEmpty) {
                        return const Center(child: Text("Aucune donnée"));
                      }

                      return ListView.builder(
                        itemCount: parsed.length,
                        itemBuilder: (context, index) {
                          final item = parsed[index];
                          final doc = item['doc'] as DocumentSnapshot;
                          final recette = item['recette'] as double;
                          final createdBy = item['createdBy'];
                          final parsedDate = item['parsedDate'] as DateTime?;
                          final dateFormatted = parsedDate != null
                              ? DateFormat('dd/MM/yy').format(parsedDate)
                              : (item['date'] ?? '');

                          final isEven = index.isEven;
                          final rowColor = isEven
                              ? colorScheme.surfaceVariant.withOpacity(0.3)
                              : Colors.white;

                          final row = InkWell(
                            onTap: () => canEdit
                            ? turnoverController.editTurnoverDialog(
                                context,
                                widget.stand.id,
                                doc.id,
                                doc.data() as Map<String, dynamic>,
                                isStand: !widget.isShop,
                              )
                            : null,
                            onLongPress: canDelete
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Confirmer la suppression"),
                                    content: Text(
                                        "Supprimer l’entrée du $dateFormatted (${recette.toStringAsFixed(2)} €) ?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text("Annuler"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
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
                                  await turnoverRef.doc(doc.id).delete();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Entrée du $dateFormatted supprimée ✅",
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16,
                              ),
                              color: rowColor,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      dateFormatted,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        "${recette.toStringAsFixed(2)} €",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        createdBy,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // === Ligne total du mois ===
                          if (parsedDate != null) {
                            final m = parsedDate.month;
                            final y = parsedDate.year;
                            final nextDate = index < parsed.length - 1
                            ? parsed[index + 1]['parsedDate'] as DateTime?
                            : null;
                            final isLastOfMonth = nextDate == null || nextDate.month != m || nextDate.year != y;
                            if (isLastOfMonth) {
                              double monthlyTotal = 0;
                              final monthData = parsed.where((d) {
                                final dDate = d['parsedDate'] as DateTime?;
                                return dDate != null && dDate.month == m && dDate.year == y;
                              }).toList();

                              for (var d in monthData) {
                                monthlyTotal += (d['recette'] as double);
                              }

                              return Column(
                                children: [
                                  row,
                                  Dismissible(
                                    key: ValueKey("total_${m}_$y"),
                                    direction: DismissDirection.horizontal,
                                    background: Container(
                                      color: canDelete ? Colors.red : Colors.grey,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text("Supprimer toutes les entrées",
                                              style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.green,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
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
                                      if (direction == DismissDirection.startToEnd) {
                                        // suppression mois
                                        if (!canDelete) return false;
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Confirmer la suppression"),
                                            content: Text(
                                                "Voulez-vous supprimer toutes les entrées de ${turnoverController.monthName(m)} $y ?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text("Annuler"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text("Supprimer",
                                                  style: TextStyle( color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          for (final d in monthData) {
                                            await turnoverRef.doc(d['doc'].id).delete();
                                          }
                                          if (!mounted) return false;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Toutes les entrées de ${turnoverController.monthName(m)} $y supprimées ✅",
                                              ),
                                            ),
                                          );
                                        }
                                        return false;
                                      } else if (direction == DismissDirection.endToStart) {
                                        // génération PDF
                                        await pdfController.generateMonthlyPdfLocally(
                                          stand: widget.stand,
                                          isShop: widget.isShop,
                                          month: m,
                                          year: y,
                                          total: monthlyTotal,
                                          data: monthData.cast<Map<String, dynamic>>(),
                                        );
                                        await _loadPdfFiles();
                                        if (!mounted) return false;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "PDF ${turnoverController.monthName(m)} $y généré ✅",
                                            ),
                                          ),
                                        );
                                        return false;
                                      }
                                      return false;
                                    },
                                    child: Container(
                                      color: Colors.green.shade200,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                                                "${monthlyTotal.toStringAsFixed(2)} €",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Expanded(
                                            flex: 2, child: SizedBox(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          }
                          return row;
                        },
                      );
                    },
                  ),
                ),

                // === Liste PDF visible avec animation ===
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: child,
                  ),
                  child: showPdfList && pdfFiles.isNotEmpty
                  ? Container(
                      key: const ValueKey('pdf_list'),
                      padding: const EdgeInsets.all(10),
                      color: colorScheme.surfaceVariant.withOpacity(0.4),
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📄 Fichiers PDF enregistrés",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: pdfFiles.length,
                              itemBuilder: (context, index) {
                                final file = pdfFiles[index];
                                return BuildCardPdfWidget(
                                  file: file,
                                  parentContext: context,
                                  pdfController: pdfController,
                                  standId: widget.stand.id,
                                  isShop: widget.isShop,
                                  canDelete: canDelete,
                                  reloadList: _loadPdfFiles,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
                ),
              ],
            ),

            // === Bouton flottant "Voir / Cacher les PDFs" ===
            Positioned(
              bottom: showPdfList
              ? MediaQuery.of(context).size.height * 0.37
              : 20, // placé au-dessus de la liste ouverte
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: colorScheme.secondaryContainer,
                icon: Icon(
                  showPdfList
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                ),
                label: Text(
                  showPdfList ? "Cacher les PDFs" : "Voir les PDFs",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (pdfFiles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Aucun PDF enregistré")),
                    );
                    return;
                  }
                  setState(() => showPdfList = !showPdfList);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary,
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
                style:TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Créé par",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}