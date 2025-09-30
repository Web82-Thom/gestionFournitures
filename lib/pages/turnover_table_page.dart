import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
class _TurnoverTablePageState extends State<TurnoverTablePage> {
  late CollectionReference turnoverRef;

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
  String monthName(int month) {
    const months = [
      "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ];
    return months[month - 1];
  }
  /// Ajouter un chiffre d'affaire
  void _addTurnoverDialog() {
    final recetteController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Ajouter un chiffre d'affaire"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? "Sélectionner une date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        locale: const Locale('fr'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: recetteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Recette (€)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null) {
                  final recette = double.tryParse(recetteController.text) ?? 0;
                  await turnoverRef.add({
                    'date':
                        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    'recette': recette,
                    'isShop': widget.isShop, // Sauvegarde du type
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Chiffre d'affaire ajouté ✅")),
                  );
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }

  /// Modifier une ligne (double tap)
  void _editTurnover(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dateController = TextEditingController(text: data['date'] ?? '');
    final recetteController =
        TextEditingController(text: (data['recette'] ?? '').toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le chiffre d'affaire"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date"),
            ),
            TextField(
              controller: recetteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Recette (€)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDate = dateController.text.trim();
              final newRecette = double.tryParse(recetteController.text) ?? 0;
              if (newDate.isNotEmpty) {
                await turnoverRef.doc(doc.id).update({
                  'date': newDate,
                  'recette': newRecette,
                  'isShop': widget.isShop, // Conserver le type
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chiffre d'affaire modifié ✅")),
                );
              }
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  /// Supprimer une ligne (appui long)
  void _deleteTurnover(DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous supprimer ce chiffre d'affaire ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await turnoverRef.doc(doc.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chiffre d'affaire supprimé ✅")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Chiffre d'affaire - ${widget.stand.name} ${widget.isShop ? '(Boutique)' : '(Stand)'}"),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ajouter",
            onPressed: _addTurnoverDialog,
          ),
        ],
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

          final docs = snapshot.data!.docs;

          // 🔹 Calcul du total selon mois/année sélectionnés
          double monthlyTotal = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] ?? '';
            final recette = (data['recette'] ?? 0).toDouble();

            try {
              final parts = dateStr.split('/');
              if (parts.length == 3) {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final docDate = DateTime(year, month, day);

                if (docDate.month == selectedMonth && docDate.year == selectedYear) {
                  monthlyTotal += recette;
                }
              }
            } catch (_) {}
          }

          return Column(
            children: [
              Center(
                child: Text(
                  widget.stand.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 🔹 Sélecteur de mois
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: selectedMonth,
                      items: List.generate(12, (index) {
                        final monthNum = index + 1;
                        return DropdownMenuItem(
                          value: monthNum,
                          child: Text(monthName(monthNum)),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedMonth = value);
                      },
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year-2 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedYear = value);
                      },
                    ),
                  ],
                ),
              ),

              // 🔹 Total du mois sélectionné
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Total de ${monthName(selectedMonth)} $selectedYear : $monthlyTotal €',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),

              Container(
                color: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text("Date",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("Recette (€)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 🔹 Tableau identique au tien
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isEven = index % 2 == 0;

                    return GestureDetector(
                      onDoubleTap: () => _editTurnover(doc),
                      onLongPress: () => _deleteTurnover(doc),
                      child: Container(
                        color: isEven ? Colors.blue.shade50 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                data['date'] ?? '',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "${data['recette'] ?? 0} €",
                                textAlign: TextAlign.center,
                              ),
                            ),
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
    );
  }}