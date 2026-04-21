import 'dart:convert';

class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  Member({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
    };
  }

  static List<Member> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Member.fromJson(json)).toList();
  }

  static List<Map<String, dynamic>> toMapList(List<Member> members) {
    return members.map((m) => m.toMap()).toList();
  }
}
