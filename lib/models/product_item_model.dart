/// 🍪 Représente un produit du stock (cookie, ingrédient, etc.)
class ProductItemModel {
  final String id;
  final String name;
  final int quantite;
  final int consomme;
  final int reste;
  final bool alerte;

  const ProductItemModel({
    required this.id,
    required this.name,
    required this.quantite,
    required this.consomme,
    required this.reste,
    required this.alerte,
  });

  factory ProductItemModel.fromMap(Map<String, dynamic> data, {String? id}) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final quantite = parseInt(data['quantite']);
    final consomme = parseInt(data['consomme']);
    final reste = parseInt(data['reste'] ?? (quantite - consomme));
    final alerte = reste < 10;

    return ProductItemModel(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? data['product'] ?? '',
      quantite: quantite,
      consomme: consomme,
      reste: reste,
      alerte: alerte,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantite': quantite,
      'consomme': consomme,
      'reste': reste,
      'alerte': alerte,
    };
  }

  ProductItemModel copyWith({
    String? id,
    String? name,
    int? quantite,
    int? consomme,
    int? reste,
    bool? alerte,
  }) {
    return ProductItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantite: quantite ?? this.quantite,
      consomme: consomme ?? this.consomme,
      reste: reste ?? this.reste,
      alerte: alerte ?? this.alerte,
    );
  }
}
