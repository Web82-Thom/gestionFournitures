// shop_stock.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ShopStockModel {
  String id;            // ID du document Firestore
  String produits;      // Nom du produit
  int quantite;         // Quantité en stock
  int consommer;        // Quantité consommée
  int reste;            // Calculé automatiquement
  String commande;      // Calculé automatiquement ⚠️ ou ✅

  ShopStockModel({
    required this.id,
    required this.produits,
    required this.quantite,
    required this.consommer,
    int? reste,
    String? commande,
  })  : reste = reste ?? quantite - consommer,
        commande = commande ?? ((reste ?? (quantite - consommer)) < 10 ? '⚠️' : '✅');

  /// Créer un objet ShopStock à partir d'un DocumentSnapshot Firestore
  factory ShopStockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Conversion sécurisée en int pour éviter les erreurs de type
    int quant = int.tryParse(data['quantite'].toString()) ?? 0;
    int conso = int.tryParse(data['consommer'].toString()) ?? 0;
    int resteCalc = quant - conso;
    String cmd = resteCalc < 10 ? '⚠️' : '✅';

    return ShopStockModel(
      id: doc.id,
      produits: data['produits'] ?? '',
      quantite: quant,
      consommer: conso,
      reste: resteCalc,
      commande: cmd,
    );
  }

  /// Convertir l'objet en Map pour sauvegarder dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'produits': produits,
      'quantite': quantite,
      'consommer': consommer,
      // On ne stocke pas "reste" et "commande", car ce sont des champs calculés
    };
  }

  /// Mettre à jour une cellule et recalculer reste et commande
  void updateCell({int? quantite, int? consommer}) {
    this.quantite = quantite ?? this.quantite;
    this.consommer = consommer ?? this.consommer;
    reste = this.quantite - this.consommer;
    commande = reste < 10 ? '⚠️' : '✅';
  }

  /// Créer une copie modifiée de l'objet (utile pour l'édition)
  ShopStockModel copyWith({
    String? produits,
    int? quantite,
    int? consommer,
  }) {
    int newQuant = quantite ?? this.quantite;
    int newConso = consommer ?? this.consommer;
    int newReste = newQuant - newConso;

    return ShopStockModel(
      id: id,
      produits: produits ?? this.produits,
      quantite: newQuant,
      consommer: newConso,
      reste: newReste,
      commande: newReste < 10 ? '⚠️' : '✅',
    );
  }
}
