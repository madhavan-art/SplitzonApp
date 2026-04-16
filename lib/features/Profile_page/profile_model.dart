// lib/data/models/user_model.dart
import 'dart:convert';

class UserModel {
  final String id;
  String name;
  String email;
  String phone;
  String profilePicture;
  bool darkMode;
  String language;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePicture = '',
    this.darkMode = false,
    this.language = 'English (US)',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profilePicture: map['profilePicture'] ?? map['profile'] ?? '',
      darkMode: map['darkMode'] ?? false,
      language: map['language'] ?? 'English (US)',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
      'darkMode': darkMode,
      'language': language,
    };
  }
}

// class UserModel {
//   String name;
//   String email;
//   String phone;
//   bool darkMode;
//   String language;

//   UserModel({
//     required this.name,
//     required this.email,
//     required this.phone,
//     this.darkMode = false,
//     this.language = 'English (US)',
//   });
// }
