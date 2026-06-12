import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class ReorderService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static Future<Map<String, dynamic>> getRekomendasi({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/reorder-point/rekomendasi?limit=$limit&offset=$offset"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Gagal ambil rekomendasi reorder');
    }
  }
}
