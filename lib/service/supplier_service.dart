import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class SupplierService {
  static const String baseUrl = 'https://skripsi.crossnet.co.id:8080/supplier';

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static Future<List<dynamic>> getAllSuppliers({
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl?limit=$limit&offset=$offset');
    print("📡 GET supplier → $uri");
    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    print("📡 Status: ${response.statusCode}");
    print("📡 Response: ${response.body}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception('Gagal ambil supplier (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getDetailSupplier(int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/$id'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal ambil detail supplier');
    }
  }

  static Future<void> addSupplier(Map<String, dynamic> data) async {
    final response = await http
        .post(
          Uri.parse(baseUrl),
          headers: _authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal tambah supplier';
      throw Exception(msg);
    }
  }

  static Future<void> editSupplier(Map<String, dynamic> data) async {
    final response = await http
        .put(
          Uri.parse(baseUrl),
          headers: _authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal edit supplier';
      throw Exception(msg);
    }
  }

  static Future<void> deleteSupplier(int id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/$id'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal hapus supplier (${response.statusCode})');
    }
  }
}
