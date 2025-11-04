import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente un utilisateur de l'application (admin, gérant, collaborateur…)
class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final UserRole role;
  final List<String> shopIds; 
  final List<String> standIds;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.role,
    this.shopIds = const [],
    this.standIds = const [],
    required this.createdAt,
  });

  /// Convertit un utilisateur en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'role': role.name,
      'shopIds': shopIds,
      'standIds': standIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Alias JSON (utile pour certaines libs)
  Map<String, dynamic> toJson() => toMap();

  /// Création depuis une Map (ex: JSON, Firestore data)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'collaborateur'),
      shopIds: List<String>.from(map['shopIds'] ?? []),
      standIds: List<String>.from(map['standIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
    );
  }

  /// Création depuis un document Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Le document utilisateur ${doc.id} est vide");
    }
    return UserModel.fromMap({
      ...data,
      'uid': data['uid'] ?? doc.id, // doc.id utilisé si champ uid absent
    });
  }

  /// ✨ Crée une copie en modifiant certains champs
  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    UserRole? role,
    List<String>? shopIds,
    List<String>? standIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      shopIds: shopIds ?? this.shopIds,
      standIds: standIds ?? this.standIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Enum pour les rôles utilisateurs
enum UserRole { admin, manager, collaborateur }

/// Extension pratique pour convertir entre String <-> Enum
extension UserRoleExtension on UserRole {
  String get name => toString().split('.').last;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.collaborateur;
    }
  }
}
