import 'package:flutter/material.dart';

class LaBoutiquePage extends StatefulWidget {
  const LaBoutiquePage({super.key});

  @override
  State<LaBoutiquePage> createState() => _LaBoutiquePageState();
}

class _LaBoutiquePageState extends State<LaBoutiquePage> {
  List<Map<String, dynamic>> _rows = [
    {"produits": "Boite", "quantite": 50, "consommer": 45, "reste": 5, "commande": ""},
    {"produits": "Carton", "quantite": 100, "consommer": 50, "reste": 50, "commande": ""},
    {"produits": "Papier", "quantite": 100, "consommer": 80, "reste": 20, "commande": ""},
  ];

  late List<TextEditingController> _quantiteControllers;
  late List<TextEditingController> _consoControllers;

  @override
  void initState() {
    super.initState();
    _updateAllRows();

    _quantiteControllers =
        _rows.map((r) => TextEditingController(text: r['quantite'].toString())).toList();
    _consoControllers =
        _rows.map((r) => TextEditingController(text: r['consommer'].toString())).toList();
  }

  void _updateAllRows() {
    setState(() {
      _rows = _rows.map((r) {
        final reste = r['quantite'] - r['consommer'];
        return {
          ...r,
          'reste': reste,
          'commande': reste < 10 ? "⚠️" : "✅",
        };
      }).toList();
    });
  }

  void _updateCell(int index, String key, String value) {
    setState(() {
      int parsedValue = int.tryParse(value) ?? 0;
      _rows[index][key] = parsedValue;
      _updateAllRows();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("La Boutique - Stock")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "📦 Stock Boutique",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    color: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text('Prdt', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Qté stock', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Conso', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('Reste', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('Cmd', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  // Lignes
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final isEven = index % 2 == 0;
                        return Container(
                          color: isEven ? Colors.blue.shade50 : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(row['produits'].toString(), textAlign: TextAlign.center)),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _quantiteControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) => _updateCell(index, 'quantite', value),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _consoControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) => _updateCell(index, 'consommer', value),
                                ),
                              ),
                              Expanded(flex: 1, child: Text(row['reste'].toString(), textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text(row['commande'].toString(), textAlign: TextAlign.center)),
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
