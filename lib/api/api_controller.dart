// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   /// 🔥 CHANGE IP if real device
//   static const String baseUrl =
//       "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/auth";
//   // static const String baseUrl = "http://192.168.0.10:4999/api/auth";

//   /// ===============================
//   /// SIGNUP CHECK (STEP 1)
//   /// ===============================
//   static Future<Map<String, dynamic>> signupCheck({
//     required String name,
//     required String email,
//     required String phone,
//   }) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/signup"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"name": name, "email": email, "phone": phone}),
//     );

//     return jsonDecode(res.body);
//   }

//   /// ===============================
//   /// SIGNUP COMPLETE (STEP 2)
//   /// ===============================
//   static Future<Map<String, dynamic>> signupComplete({
//     required String name,
//     required String email,
//     required String phone,
//     required String firebaseUid,
//   }) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/signup/complete"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "name": name,
//         "email": email,
//         "phone": phone,
//         "firebaseUid": firebaseUid,
//       }),
//     );

//     return jsonDecode(res.body);
//   }

//   /// ===============================
//   /// LOGIN CHECK
//   /// ===============================
//   static Future<Map<String, dynamic>> loginCheck({
//     required String phone,
//   }) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/login"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"phone": phone}),
//     );

//     return jsonDecode(res.body);
//   }

//   /// ===============================
//   /// LOGIN COMPLETE
//   /// ===============================
//   static Future<Map<String, dynamic>> loginComplete({
//     required String firebaseUid,
//   }) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/login/complete"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"firebaseUid": firebaseUid}),
//     );

//     return jsonDecode(res.body);
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/auth";

  static Future<Map<String, dynamic>> signupCheck({
    required String name,
    required String email,
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "phone": phone}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> signupComplete({
    required String name,
    required String email,
    required String phone,
    required String firebaseUid,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signup/complete"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "phone": phone,
        "firebaseUid": firebaseUid,
      }),
    );
    return jsonDecode(res.body);
  }

  // ✅ Fixed: was /login, now /signin
  static Future<Map<String, dynamic>> signinCheck({
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
    return jsonDecode(res.body);
  }

  // ✅ Fixed: was /login/complete, now /signin/complete
  static Future<Map<String, dynamic>> loginComplete({
    required String firebaseUid,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signin/complete"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"firebaseUid": firebaseUid}),
    );
    return jsonDecode(res.body);
  }
}
