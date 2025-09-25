import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChiffreAffairePage extends StatelessWidget {
  const ChiffreAffairePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chiffre d'Affaires"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Carte du chiffre d'affaire total
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  children: const [
                    Text(
                      "Chiffre d’Affaires Total",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "150 000 €",
                      style: TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Graphique
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text("Jan");
                                case 1:
                                  return const Text("Fév");
                                case 2:
                                  return const Text("Mar");
                                case 3:
                                  return const Text("Avr");
                                case 4:
                                  return const Text("Mai");
                                case 5:
                                  return const Text("Juin");
                              }
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 12000),
                            FlSpot(1, 15000),
                            FlSpot(2, 18000),
                            FlSpot(3, 16000),
                            FlSpot(4, 20000),
                            FlSpot(5, 22000),
                          ],
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
