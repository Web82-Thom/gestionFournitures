import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';
import 'package:gestion_fournitures/widgets/animated_cookie_background_mouve.dart';
import 'package:gestion_fournitures/widgets/build_grid_widget.dart';
import 'package:gestion_fournitures/widgets/build_section_title_widget.dart';

class TurnoversPage extends StatelessWidget {
  const TurnoversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final standsCollection = FirebaseFirestore.instance.collection('stands');
    final boutiquesCollection = FirebaseFirestore.instance.collection('boutiques');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chiffres d'affaires"),
        backgroundColor: colorScheme.primary,
        centerTitle: true,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          const AnimatedCookieBackgroundMouve(
            cookieImage: 'assets/images/cookie.png',
            count: 10,
            size: 55,
            speed: 0.00095,
            opacity: 0.25,
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: FutureBuilder<QuerySnapshot>(
                future: boutiquesCollection.get(),
                builder: (context, boutiqueSnapshot) {
                  if (boutiqueSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                        
                  if (!boutiqueSnapshot.hasData || boutiqueSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Aucune boutique disponible"));
                  }
                        
                  final boutiques = boutiqueSnapshot.data!.docs.map((doc) {
                    return ShopStandModel(
                      id: doc.id,
                      name: doc['name'] ?? 'Boutique',
                    );
                  }).toList();
                        
                  return StreamBuilder<QuerySnapshot>(
                    stream: standsCollection.snapshots(),
                    builder: (context, standSnapshot) {
                      if (standSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                        
                      if (!standSnapshot.hasData || standSnapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Aucun stand disponible"));
                      }
                        
                      final stands = standSnapshot.data!.docs
                          .map((doc) => ShopStandModel.fromFirestore(doc))
                          .toList();
                        
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BuildSectionTitleWidget(title:"🏬 Boutiques"),
                            BuildGridWidget(
                              items: boutiques,
                              isShop: true,
                              backgroundColor: Colors.green.shade200,
                            ),
                            const Divider(),
                            BuildSectionTitleWidget(title:"🧁 Stands"),
                            BuildGridWidget(
                              items: stands,
                              isShop: false,
                              backgroundColor: Colors.blue.shade200,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}