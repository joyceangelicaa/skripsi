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
    int limit = 10, int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/reorder-point/rekomendasi?limit=$limit&offset=$offset"),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['data'];
      if (result == null) throw Exception('Data rekomendasi kosong');
      return result as Map<String, dynamic>;
    } else {
      throw Exception('Gagal ambil rekomendasi reorder');
    }
  }

  static Future<void> hitungSemua() async {
    final response = await http.post(
      Uri.parse("$baseUrl/reorder-point/hitung-semua"),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghitung ulang ROP');
    }
  }

  static Future<List<dynamic>> getProdukWithStatus({
    int limit = 10, int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/reorder-point/produk?limit=$limit&offset=$offset"),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['data'];
      if (result == null) throw Exception('Data produk kosong');
      return result as List<dynamic>;
    } else {
      throw Exception('Gagal ambil produk dengan status');
    }
  }
}
