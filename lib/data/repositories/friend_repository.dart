import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:splitzon/services/storage_service.dart';
import '../models/friend_model.dart';

class FriendRepository {
  final String baseUrl;

  FriendRepository(this.baseUrl);

  Future<List<FriendModel>> getFriends() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/friends/my-friends"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      return (data["data"] as List)
          .map((e) => FriendModel.fromJson(e))
          .toList();
    }

    return [];
  }
}
