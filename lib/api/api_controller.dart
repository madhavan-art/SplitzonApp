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
import 'package:flutter/foundation.dart';

class ApiService {
  // Allow dynamic base URL for testing
  static String baseUrl =
      "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/auth";

  // Set base URL dynamically (for testing different environments)
  static void setBaseUrl(String url) {
    baseUrl = url;
    debugPrint('🔧 API Base URL set to: $baseUrl');
  }

  // Generic HTTP request helper with error handling
  static Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final requestHeaders = {'Content-Type': 'application/json', ...?headers};

      if (authToken != null) {
        requestHeaders['Authorization'] = 'Bearer $authToken';
      }

      debugPrint('📡 Making $method request to: $url');
      if (body != null) {
        debugPrint('📤 Request body: ${jsonEncode(body)}');
      }

      late final http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        // Return error structure
        return {
          'success': false,
          'message':
              'HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
          'status': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ API Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // SIGNUP CHECK (STEP 1)
  static Future<Map<String, dynamic>> signupCheck({
    required String name,
    required String email,
    required String phone,
  }) async {
    return await _makeRequest(
      endpoint: 'signup',
      method: 'POST',
      body: {"name": name, "email": email, "phone": phone},
    );
  }

  // SIGNUP COMPLETE (STEP 2)
  static Future<Map<String, dynamic>> signupComplete({
    required String name,
    required String email,
    required String phone,
    required String firebaseUid,
  }) async {
    return await _makeRequest(
      endpoint: 'signup/complete',
      method: 'POST',
      body: {
        "name": name,
        "email": email,
        "phone": phone,
        "firebaseIdToken": firebaseUid,
      },
    );
  }

  // LOGIN CHECK
  static Future<Map<String, dynamic>> signinCheck({
    required String phone,
  }) async {
    return await _makeRequest(
      endpoint: 'signin',
      method: 'POST',
      body: {"phone": phone},
    );
  }

  // LOGIN COMPLETE
  static Future<Map<String, dynamic>> loginComplete({
    required String firebaseUid,
  }) async {
    return await _makeRequest(
      endpoint: 'signin/complete',
      method: 'POST',
      body: {"firebaseIdToken": firebaseUid},
    );
  }
}
