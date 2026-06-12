import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class LaporanStokService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static Future<Map<String, dynamic>> getLaporanStok({
    String? startDate,
    String? endDate,
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/laporan-stok?start_date=${startDate ?? ""}&end_date=${endDate ?? ""}&limit=$limit&offset=$offset",
    );

    final response = await http.get(
      uri,
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Gagal mengambil laporan stok");
    }
  }
}