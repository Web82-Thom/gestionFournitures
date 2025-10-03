import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String role;
  final List<String> shopIds; 
  final List<String> standIds;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.role,
    this.shopIds = const [],
    this.standIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'role': role,
      'shopIds': shopIds,
      'standIds': standIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      role: map['role'] ?? 'associe',
      shopIds: List<String>.from(map['shopIds'] ?? []),
      standIds: List<String>.from(map['standIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }
  //Avec cette méthode, vous pouvez facilement convertir un document Firestore en une instance de UserModel.
  // final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  // final user = UserModel.fromFirestore(doc);
  // print(user.nickname);
  
  /// ✨ Permet de cloner l'objet en modifiant uniquement certains champs
  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? role,
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
