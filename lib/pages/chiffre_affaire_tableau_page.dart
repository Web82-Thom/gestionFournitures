import 'package:flutter/material.dart';
import 'package:gestion_fournitures/models/stand_model.dart'; // ton modèle

class ChiffreAffaireTableauPage extends StatelessWidget {
  final StandModel stand;

  const ChiffreAffaireTableauPage({super.key, required this.stand});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chiffre d'affaire - ${stand.name}"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📊 Tableau Chiffre d'affaire du stand : ${stand.name}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    color: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text("Date", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("Recette", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  // Lignes vides
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final isEven = index % 2 == 0;
                        return Container(
                          color: isEven ? Colors.green.shade50 : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text("", textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text("", textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text("", textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text("", textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text("", textAlign: TextAlign.center)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
