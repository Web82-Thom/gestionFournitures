// shop_stock.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ShopStockModel {
  String id;
  String produits;
  int quantite;
  int consommer;
  int reste;
  String commande;

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
  /// Crée à partir d'une Map (sécurise types et conversions)
  factory ShopStockModel.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    final produits = (map['produits'] ?? '').toString();
    final quantite = int.tryParse(map['quantite']?.toString() ?? '') ?? 0;
    final consommer = int.tryParse(map['consommer']?.toString() ?? '') ?? 0;
    final reste = quantite - consommer;
    final commande = reste < 10 ? '⚠️' : '✅';

    return ShopStockModel(
      id: id,
      produits: produits,
      quantite: quantite,
      consommer: consommer,
      reste: reste,
      commande: commande,
    );
  }
  

  Map<String, dynamic> toFirestore() {
    final resteCalc = quantite - consommer;
    return {
      'produits': produits,
      'quantite': quantite,
      'consommer': consommer,
      'reste': resteCalc,
      'commande': resteCalc < 10 ? "⚠️" : "✅",
    };
  }

  /// Crée un produit à partir d'un DocumentSnapshot
  factory ShopStockModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final quantite = int.tryParse(data['quantite']?.toString() ?? '') ?? 0;
    final consommer = int.tryParse(data['consommer']?.toString() ?? '') ?? 0;
    final reste = quantite - consommer;
    final commande = reste < 10 ? "⚠️" : "✅";

    return ShopStockModel(
      id: doc.id,
      produits: data['produits'] ?? '',
      quantite: quantite,
      consommer: consommer,
      reste: reste,
      commande: commande,
    );
  }
}
