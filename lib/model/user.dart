// lib/data/models/user.dart (or wherever it is)
import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profile;
  final String syncStatus;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profile,
    this.syncStatus = 'SYNCED',
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profile: map['profilePicture'] ?? map['profile'] ?? '',
      syncStatus: map['syncStatus'] ?? 'SYNCED',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile': profile,
      'syncStatus': syncStatus,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profile,
    String? syncStatus,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profile: profile ?? this.profile,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

// import 'dart:convert';

// class User {
//   final String id;
//   final String name;
//   final String email;
//   final String phone;
//   final String profile;

//   User({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.profile,
//   });

//   factory User.fromMap(Map<String, dynamic> map) {
//     return User(
//       id: map['_id'] ?? map['id'] ?? '',
//       name: map['name'] ?? '',
//       email: map['email'] ?? '',
//       phone: map['phone'] ?? '',
//       profile: map['profilePicture'] ?? map['profile'] ?? '',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'email': email,
//       'phone': phone,
//       'profile': profile,
//     };
//   }

//   String toJson() => json.encode(toMap());

//   factory User.fromJson(String source) =>
//       User.fromMap(json.decode(source) as Map<String, dynamic>);
// }
