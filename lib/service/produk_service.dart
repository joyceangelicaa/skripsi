import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class ProdukService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static Future<List<dynamic>> getAllProduk({
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse("$baseUrl/produk?limit=$limit&offset=$offset");
    print("📡 GET produk → $uri");
    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    print("📡 Status: ${response.statusCode}");
    print("📡 Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Gagal ambil data produk (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getDetailProduk(String kode) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/produk/$kode"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal ambil detail produk');
    }
  }

  static Future<void> addProduk(Map<String, dynamic> data) async {
    // data['reorder_point'] = 0;

    final response = await http
        .post(
          Uri.parse("$baseUrl/produk"),
          headers: _authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal tambah produk';
      throw Exception(msg);
    }
  }

  static Future<void> editProduk(Map<String, dynamic> data) async {
    data['reorder_point'] = 0;

    final response = await http
        .put(
          Uri.parse("$baseUrl/produk"),
          headers: _authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal edit produk';
      throw Exception(msg);
    }
  }

  static Future<void> deleteProduk(String kode) async {
    final response = await http
        .delete(
          Uri.parse("$baseUrl/produk/$kode"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal hapus produk (${response.statusCode})');
    }
  }
}
