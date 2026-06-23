import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class CustomerService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static Future<List<dynamic>> getAllCustomer({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/customer?limit=$limit&offset=$offset"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception("Gagal ambil customer (${response.statusCode})");
    }
  }

  static Future<Map<String, dynamic>> getDetailCustomer(int id) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/customer/$id"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Customer tidak ditemukan");
    }
  }

  static Future<void> addCustomer({
    required String namaCustomer,
    required String noTelp,
    required String alamat,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/customer"),
          headers: _authHeaders(),
          body: jsonEncode({
            "nama_customer": namaCustomer,
            "no_telp": noTelp,
            "alamat": alamat,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal tambah customer';
      throw Exception(msg);
    }
  }

  static Future<void> editCustomer({
    required int idCustomer,
    required String namaCustomer,
    required String noTelp,
    required String alamat,
  }) async {
    final response = await http
        .put(
          Uri.parse("$baseUrl/customer"),
          headers: _authHeaders(),
          body: jsonEncode({
            "id_customer": idCustomer,
            "nama_customer": namaCustomer,
            "no_telp": noTelp,
            "alamat": alamat,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal edit customer';
      throw Exception(msg);
    }
  }

  static Future<double?> getCustomerHarga({
    required String kodeProduk,
    required int idCustomer,
  }) async {
    final url = "$baseUrl/customer/harga/$kodeProduk/$idCustomer/1";
    debugPrint('GET $url');
    final response = await http
        .get(
          Uri.parse(url),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final data = result['data'] as List?;
      if (data != null && data.isNotEmpty) {
        return (data[0]['harga'] as num).toDouble();
      }
    }
    return null;
  }

  static Future<void> deleteCustomer(int idCustomer) async {
    final response = await http
        .delete(
          Uri.parse("$baseUrl/customer/$idCustomer"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal hapus customer (${response.statusCode})');
    }
  }
}
