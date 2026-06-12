import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class KartuStokService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  // =========================
  // GET ALL KARTU STOK
  // =========================
  static Future<List<dynamic>> getAllKartuStok({
    int limit = 10,
    int offset = 0,
  }) async {
    final url = Uri.parse(
      "$baseUrl/kartu-stok?limit=$limit&offset=$offset",
    );

    final response = await http.get(
      url,
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['data']['items'] ?? [];
    } else {
      throw Exception("Failed to load kartu stok");
    }
  }

  // =========================
  // GET KARTU STOK BY PRODUK
  // =========================
  static Future<List<dynamic>> getKartuStokByProduk({
    required String kodeProduk,
    String? startDate,
    String? endDate,
  }) async {
    String urlStr =
        "$baseUrl/kartu-stok/$kodeProduk";

    if (startDate != null && endDate != null) {
      urlStr += "?start_date=$startDate&end_date=$endDate";
    }

    final url = Uri.parse(urlStr);

    final response = await http.get(
      url,
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['items'] ?? [];
    } else {
      throw Exception("Failed to load kartu stok produk");
    }
  }

  // =========================
  // GET DETAIL KARTU STOK
  // =========================
  static Future<Map<String, dynamic>> getDetailKartuStok({
    required String idKartuStok,
  }) async {
    final url = Uri.parse(
      "$baseUrl/kartu-stok/detail/$idKartuStok",
    );

    final response = await http.get(
      url,
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['data']['item'] ?? {};
    } else {
      throw Exception("Failed to load detail kartu stok");
    }
  }

  // =========================
  // ADD KARTU STOK
  // =========================
  static Future<Map<String, dynamic>> addKartuStok({
    required String kodeProduk,
    required int stokMasuk,
    String keteranganBarang = "",
  }) async {
    final url = Uri.parse("$baseUrl/kartu-stok");

    final response = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({
        "kode_produk": kodeProduk,
        "stok_masuk": stokMasuk,
        "keterangan_barang": keteranganBarang,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Failed to add kartu stok");
    }
  }
}