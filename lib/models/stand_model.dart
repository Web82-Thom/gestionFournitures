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
}
