class FriendModel {
  final String friendId;
  final String name;
  final String phone;
  final String email;
  final String profilePicture;

  bool isSelected;

  FriendModel({
    required this.friendId,
    required this.name,
    required this.phone,
    required this.email,
    required this.profilePicture,
    this.isSelected = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      friendId: json["friendId"] ?? "",
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
      email: json["email"] ?? "",
      profilePicture: json["profilePicture"] ?? "",
    );
  }
}
