import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final String user;
  final String action;
  final String product;
  final int reste;
  final String shop;
  final String stand;
  final DateTime? date;

  HistoryModel({
    required this.id,
    required this.user,
    required this.action,
    required this.product,
    required this.reste,
    required this.shop,
    required this.stand,
    required this.date,
  });

  factory HistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HistoryModel(
      id: doc.id,
      user: data['user'] ?? 'inconnu',
      action: data['action'] ?? '',
      product: data['produit'] ?? '',   // ✅ correspond au champ Firestore
      reste: data['reste'] ?? 0,
      shop: data['shopName'] ?? '',     // ✅ correspond à shopName
      stand: data['standName'] ?? '',   // ✅ correspond à standName
      date: (data['date'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user,
      'action': action,
      'produit': product,
      'reste': reste,
      'shopName': shop,
      'standName': stand,
      'date': date != null ? Timestamp.fromDate(date!) : null,
    };
  }
}