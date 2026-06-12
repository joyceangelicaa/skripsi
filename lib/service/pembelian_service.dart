import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class PembelianService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080/pembelian";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  // =========================
  // GET ALL PEMBELIAN
  // =========================
  static Future<List<Map<String, dynamic>>> getAllPembelian({
    int limit = 10,
    int offset = 0,
    String status = '',
  }) async {
    String url = "$baseUrl?limit=$limit&offset=$offset";
    if (status.isNotEmpty) {
      url += "&status=$status";
    }

    final res = await http.get(
      Uri.parse(url),
      headers: _authHeaders(),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      return List<Map<String, dynamic>>.from(
        data.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;

          return {
            'id': item['id_pembelian'].toString(),
            'supplier': item['id_supplier'].toString(),
            'tanggal': PembelianService.formatDate(item['tanggal_pembelian']),
            'status': item['status'] == 'selesai' ? 'Selesai' : 'Proses',
            'created_at': item ['created_at'],
          };
        }),
      );
    } else {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed get pembelian");
    }
  }

  // =========================
  // GET DETAIL PEMBELIAN
  // =========================
  static Future<Map<String, dynamic>> getDetailPembelian(String idPembelian) async {
    final uri = Uri.parse("$baseUrl/$idPembelian");
    final res = await http.get(
      uri,
      headers: _authHeaders(),
    );

    print("📡 GET DETAIL PEMBELIAN → $uri");
    print("📡 Status: ${res.statusCode}");
    print("📡 Body: ${res.body}");

    try {
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        return body['data'] ?? body;
      }

      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed get detail pembelian");
    } on FormatException {
      throw Exception(
        "Gagal load data: API $uri mengembalikan response yang tidak valid.\n"
        "Status: ${res.statusCode}\nBody: ${res.body}",
      );
    }
  }

  // =========================
  // ADD PEMBELIAN (HEADER ONLY)
  // =========================
  static Future<String> addPembelian({
    required int idSupplier,
  }) async {
    final body = {
      "id_supplier": idSupplier,
    };

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    print("Response status: ${res.statusCode}");
    print("Response body: ${res.body}");

    if (res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed add pembelian");
    }

    final resBody = jsonDecode(res.body);
    final data = resBody['data'];
    if (data == null || data['id_pembelian'] == null) {
      throw Exception("Response tidak mengandung id_pembelian: ${res.body}");
    }
    return data['id_pembelian'] as String;
  }

  // =========================
  // ADD DETAIL PEMBELIAN
  // =========================
  static Future<void> addDetailPembelian(
    List<Map<String, dynamic>> details,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/detail"),
      headers: _authHeaders(),
      body: jsonEncode(details),
    );

    if (res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed add detail pembelian");
    }
  }

  // =========================
  // EDIT PEMBELIAN (HEADER ONLY)
  // =========================
  static Future<void> editPembelian({
    required String idPembelian,
    required int idSupplier,
  }) async {
    final body = {
      "id_pembelian": idPembelian,
      "id_supplier": idSupplier,
    };

    final res = await http.put(
      Uri.parse(baseUrl),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed edit pembelian");
    }
  }

  // =========================
  // EDIT DETAIL PEMBELIAN
  // =========================
  static Future<void> editDetailPembelian({
    required String idPembelian,
    required List<Map<String, dynamic>> details,
  }) async {
    final body = {
      "id_pembelian": idPembelian,
      "detail_pembelian": details,
    };

    final res = await http.put(
      Uri.parse("$baseUrl/detail"),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed edit detail pembelian");
    }
  }

  // =========================
  // DELETE PEMBELIAN
  // =========================
  static Future<void> deletePembelian(String idPembelian) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/$idPembelian"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed delete pembelian");
    }
  }

  // =========================
  // DELETE DETAIL PEMBELIAN
  // =========================
  static Future<void> deleteDetailPembelian(int idDetailPembelian) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/detail/$idDetailPembelian"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed delete detail pembelian");
    }
  }

  // =========================
  // SELESAIKAN PEMBELIAN
  // =========================
  static Future<void> selesaiPembelian(String idPembelian) async {
    final res = await http.put(
      Uri.parse("$baseUrl/$idPembelian/selesai"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Failed selesai pembelian");
    }
  }
}
