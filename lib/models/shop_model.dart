import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un produit du stock
class ShopModel {
  String id;
  String produits;
  int quantite;
  int consommer;
  int reste;
  String commande;
  String standId; // id du stand si ce produit appartient à un stand
  String standName; // nom du stand ou 'Boutique'

  ShopModel({
    required this.id,
    required this.produits,
    required this.quantite,
    required this.consommer,
    required this.reste,
    required this.commande,
    this.standId = '',
    this.standName = '',
  });

  /// Création depuis un document Firestore
  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final quantite = parseInt(data['quantite']);
    final consommer = parseInt(data['consommer']);

    return ShopModel(
      id: doc.id,
      produits: data['produits'] ?? '',
      quantite: quantite,
      consommer: consommer,
      reste: quantite - consommer,
      commande: (quantite - consommer) < 10 ? "⚠️" : "✅",
    );
  }

  /// Convertir en Map pour sauvegarde dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'produits': produits,
      'quantite': quantite,
      'consommer': consommer,
      'reste': reste,
      'commande': commande,
    };
  }
}

/// Modèle pour une ligne du chiffre d'affaire
class ChiffreAffaireItem {
  String id;
  DateTime date;
  double recette;

  ChiffreAffaireItem({
    required this.id,
    required this.date,
    required this.recette,
  });

  
  factory ChiffreAffaireItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChiffreAffaireItem(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      recette: (data['recette'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'recette': recette,
    };
  }
}

/// Modèle complet de la boutique ou du stand
class BoutiqueModel {
  String id;
  String nom;
  List<ShopModel> stock;
  List<ChiffreAffaireItem> chiffreAffaire;

  BoutiqueModel({
    required this.id,
    required this.nom,
    required this.stock,
    required this.chiffreAffaire,
  });

  /// Création depuis le document principal
  factory BoutiqueModel.fromFirestore(DocumentSnapshot doc,
      {List<ShopModel>? stockItems,
      List<ChiffreAffaireItem>? chiffreItems}) {
    final data = doc.data() as Map<String, dynamic>;
    return BoutiqueModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      stock: stockItems ?? [],
      chiffreAffaire: chiffreItems ?? [],
    );
  }
}
