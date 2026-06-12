import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class StokOpnameService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  // =========================
  // 1. GET ALL STOK OPNAME
  // =========================
  static Future<List<dynamic>> getAllStokOpname({
    int limit = 0,
    int offset = 0,
  }) async {
    final uri = Uri.parse("$baseUrl/stok-opname")
        .replace(queryParameters: {
      "limit": limit.toString(),
      "offset": offset.toString(),
    });

    final response = await http.get(
      uri,
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['items'];
    } else {
      throw Exception("Failed to load stok opname");
    }
  }

  // =========================
  // 2. GET HEADER BY ID
  // =========================
  static Future<Map<String, dynamic>> getStokOpnameById(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/stok-opname/$id"),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['items'];
    } else {
      throw Exception("Failed to load stok opname detail");
    }
  }

  // =========================
  // 3. CREATE STOK OPNAME (HEADER)
  // =========================
  static Future<Map<String, dynamic>> addStokOpname(int idUser) async {
    final response = await http.post(
      Uri.parse("$baseUrl/stok-opname"),
      headers: _authHeaders(),
      body: jsonEncode({
        "id_user": idUser,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? "Failed to create stok opname");
    }
  }

  // =========================
  // 4. GET DETAIL OPNAME
  // =========================
  static Future<List<dynamic>> getDetailStokOpname(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/stok-opname/$id/detail"),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['items'];
    } else {
      throw Exception("Failed to load detail stok opname");
    }
  }

  // =========================
  // 5. ADD DETAIL OPNAME
  // =========================
  static Future<void> addDetailOpname(
      List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse("$baseUrl/stok-opname/detail"),
      headers: _authHeaders(),
      body: jsonEncode(items),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? "Failed to save detail opname");
    }
  }
}