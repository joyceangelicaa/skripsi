import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class PenerimaanService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  // =========================
  // GET ALL PENERIMAAN
  // =========================
  static Future<List<dynamic>> getAllPenerimaan({
    int limit = 10,
    int offset = 0,
    String status = '',
  }) async {
    final uri = Uri.parse(
      "$baseUrl/penerimaan?limit=$limit&offset=$offset&status=$status",
    );

    final response = await http.get(
      uri,
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception("Gagal ambil data penerimaan (${response.statusCode})");
    }
  }

  // =========================
  // GET DETAIL PENERIMAAN
  // =========================
  static Future<Map<String, dynamic>> getDetailPenerimaan(String id) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/penerimaan/$id"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil detail penerimaan");
    }
  }

  // =========================
  // ADD PENERIMAAN (HEADER ONLY)
  // =========================
  static Future<String> addPenerimaan({
    required String idPembelian,
    required int totalHarga,
  }) async {
    final body = {
      "id_pembelian": idPembelian,
      "total_harga": totalHarga,
    };

    final response = await http
        .post(
          Uri.parse("$baseUrl/penerimaan"),
          headers: _authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> resBody = jsonDecode(response.body);
      final data = resBody['data'];
      if (data == null || data['id_penerimaan'] == null) {
        throw Exception("Response tidak mengandung id_penerimaan: ${response.body}");
      }
      return data['id_penerimaan'] as String;
    } else {
      throw Exception(
        "Gagal tambah penerimaan (${response.statusCode}) ${response.body}",
      );
    }
  }

  // =========================
  // ADD DETAIL PENERIMAAN
  // =========================
  static Future<Map<String, dynamic>> addDetailPenerimaan(
    List<Map<String, dynamic>> details,
  ) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/penerimaan/detail"),
          headers: _authHeaders(),
          body: jsonEncode(details),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        "Gagal tambah detail penerimaan (${response.statusCode}) ${response.body}",
      );
    }

    final Map<String, dynamic> resBody = jsonDecode(response.body);
    return resBody['data'] ?? {};
  }

  // =========================
  // EDIT PENERIMAAN
  // =========================
  static Future<void> editPenerimaan({
    required String idPenerimaan,
    required String idPembelian,
    required int totalHarga,
    required List<Map<String, dynamic>> details,
  }) async {
    final body = {
      "id_penerimaan": idPenerimaan,
      "id_pembelian": idPembelian,
      "total_harga": totalHarga,
      "detail_penerimaan": details,
    };

    final response = await http
        .put(
          Uri.parse("$baseUrl/penerimaan"),
          headers: _authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Gagal edit penerimaan (${response.statusCode})");
    }
  }

  // =========================
  // DELETE PENERIMAAN
  // =========================
  static Future<void> deletePenerimaan(String id) async {
    final response = await http
        .delete(
          Uri.parse("$baseUrl/penerimaan/$id"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Gagal hapus penerimaan (${response.statusCode})");
    }
  }

  // =========================
  // DELETE DETAIL
  // =========================
  static Future<void> deleteDetailPenerimaan(int idDetail) async {
    final response = await http
        .delete(
          Uri.parse("$baseUrl/penerimaan/detail/$idDetail"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Gagal hapus detail (${response.statusCode})");
    }
  }

  // =========================
  // GET NEXT BATCH CODE (PREVIEW)
  // =========================
  static Future<String> getNextBatchCode() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/penerimaan/batch/next-code"),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> resBody = jsonDecode(response.body);
      return resBody['kode_batch_penerimaan'] as String;
    } else {
      throw Exception("Gagal generate kode batch (${response.statusCode})");
    }
  }
}
