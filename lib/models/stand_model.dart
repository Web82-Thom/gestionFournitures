import 'package:cloud_firestore/cloud_firestore.dart';

class StandModel {
  final String id;
  final String name;

  StandModel({
    required this.id,
    required this.name,
  });

  factory StandModel.fromMap(String id, Map<String, dynamic> data) {
    return StandModel(
      id: id,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  /// Crée un StandModel à partir d'un DocumentSnapshot Firestore
  factory StandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StandModel(
      id: doc.id,
      name: data['name'] ?? 'Sans nom',
    );
  }
}
