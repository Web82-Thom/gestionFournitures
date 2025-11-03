import 'package:cloud_firestore/cloud_firestore.dart';

class ShopStandModel {
  final String id;
  final String name;
  final int? quantite;
  final int? consommer;
  final int? reste;
  final String? commande;
  final String standId;   // ID du stand ou de la boutique
  final String standName; // Nom du stand ou "Boutique"

  const ShopStandModel({
    required this.id,
    required this.name,
     this.quantite,
     this.consommer,
     this.reste,
     this.commande,
    this.standId = '',
    this.standName = '',
  });

  /// 🏭 Création à partir d’un document Firestore
  factory ShopStandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final quantite = parseInt(data['quantite']);
    final consommer = parseInt(data['consommer']);
    final reste = parseInt(data['reste'] ?? (quantite - consommer));
    final commande = (reste < 10) ? "⚠️" : "✅";

    return ShopStandModel(
      id: doc.id,
      name: data['name'] ?? '',
      quantite: quantite,
      consommer: consommer,
      reste: reste,
      commande: commande,
      standId: data['standId'] ?? '',
      standName: data['standName'] ?? '',
    );
  }

  /// 🔁 Conversion en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantite': quantite,
      'consommer': consommer,
      'reste': reste,
      'commande': commande,
      'standId': standId,
      'standName': standName,
    };
  }

  /// ✨ Clone avec modifications (immutable)
  ShopStandModel copyWith({
    String? id,
    String? name,
    int? quantite,
    int? consommer,
    int? reste,
    String? commande,
    String? standId,
    String? standName,
  }) {
    return ShopStandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantite: quantite ?? this.quantite,
      consommer: consommer ?? this.consommer,
      reste: reste ?? this.reste,
      commande: commande ?? this.commande,
      standId: standId ?? this.standId,
      standName: standName ?? this.standName,
    );
  }
}

//---//

/// 💰 Représente une ligne du chiffre d’affaire (recette d’un jour)
class ChiffreAffaireItem {
  final String id;
  final DateTime date;
  final double recette;

  const ChiffreAffaireItem({
    required this.id,
    required this.date,
    required this.recette,
  });

  factory ChiffreAffaireItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChiffreAffaireItem(
      id: doc.id,
      date: _parseDate(data['date']),
      recette: (data['recette'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'recette': recette,
    };
  }

  /// Helper pour parser date/Timestamp
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  ChiffreAffaireItem copyWith({
    String? id,
    DateTime? date,
    double? recette,
  }) {
    return ChiffreAffaireItem(
      id: id ?? this.id,
      date: date ?? this.date,
      recette: recette ?? this.recette,
    );
  }
}