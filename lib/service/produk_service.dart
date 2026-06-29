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
      final result = jsonDecode(response.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception('Gagal ambil data produk (${response.statusCode})');
    }
  }

  // GET ALL PRODUK BY SUPPLIER
  static Future<List<dynamic>> getProdukBySupplier({
    required int idSupplier,
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/produk/supplier/$idSupplier?limit=$limit&offset=$offset");
    print("📡 GET produk by supplier → $uri");

    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    print("📡 Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception('Gagal ambil produk by supplier (${response.statusCode})');
    }
  }

  // GET ALL PRODUK BY CUSTOMER
  static Future<List<dynamic>> getProdukByCustomer({
    required int idCustomer,
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/produk/customer/$idCustomer?limit=$limit&offset=$offset");

    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception('Gagal ambil produk by customer (${response.statusCode})');
    }
  }

  // GET Last produk by supplier
  static Future<List<dynamic>> getSupplierByProduk({
    required String kodeProduk,
  }) async {
    final uri = Uri.parse("$baseUrl/produk/$kodeProduk/supplier");
    print("📡 GET supplier by produk → $uri");

    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    print("📡 Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception('Gagal ambil supplier by produk (${response.statusCode})');
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

  static Future<Map<String, dynamic>?> getSaranSafetyStok(String kodeProduk) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/produk/safety-stock/$kodeProduk"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Gagal ambil saran safety stok (${response.statusCode})');
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
    // data['reorder_point'] = 0;

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
