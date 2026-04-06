import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profile,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profile: map['profilePicture'] ?? map['profile'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile': profile,
    };
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);
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
//     required String token,
//   });

//   factory User.fromMap(Map<String, dynamic> map) {
//     return User(
//       id: map['_id'] ?? '',
//       name: map['name'] ?? '',
//       email: map['email'] ?? '',
//       phone: map['phone'] ?? '',
//       token: map['token'] ?? '',
//       profile: map['profilePicture'] ?? '',
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
