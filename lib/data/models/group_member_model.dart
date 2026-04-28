import 'dart:convert';

class GroupMember {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profilePicture;

  const GroupMember({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profilePicture,
  });

  factory GroupMember.fromUser(dynamic user) {
    return GroupMember(
      id: user.id ?? '',
      name: user.name ?? 'Unknown',
      email: user.email,
      phone: user.phone,
      profilePicture: user.profilePicture,
    );
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] ?? map['_id'] ?? '',
      name: map['name'] ?? 'Unknown',
      email: map['email'],
      phone: map['phone'],
      profilePicture: map['profilePicture'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
    };
  }

  static List<GroupMember> fromList(List<dynamic> list) {
    return list.map((e) => GroupMember.fromMap(e)).toList();
  }

  static List<Map<String, dynamic>> toListMap(List<GroupMember> members) {
    return members.map((e) => e.toMap()).toList();
  }
}
