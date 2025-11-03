import 'package:cloud_firestore/cloud_firestore.dart';

/// 💰 Représente une ligne de chiffre d’affaire ou une recette du jour
class TurnoverItemModel {
  final String id;
  final DateTime date;
  final double montant;

  const TurnoverItemModel({
    required this.id,
    required this.date,
    required this.montant,
  });

  /// 🏭 Crée une instance à partir d’une Map (Firestore ou JSON)
  factory TurnoverItemModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return TurnoverItemModel(
      id: id ?? data['id'] ?? '',
      date: _parseDate(data['date']),
      montant: (data['montant'] as num?)?.toDouble() ??
          (data['recette'] as num?)?.toDouble() ??
          0.0,
    );
  }

  /// 🔁 Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'montant': montant,
    };
  }

  /// 🔧 Parse un champ `date` venant de Firestore (Timestamp ou String)
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  /// ✨ Copie avec modification (immutabilité)
  TurnoverItemModel copyWith({
    String? id,
    DateTime? date,
    double? montant,
  }) {
    return TurnoverItemModel(
      id: id ?? this.id,
      date: date ?? this.date,
      montant: montant ?? this.montant,
    );
  }
}
