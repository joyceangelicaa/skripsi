import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class LaporanPenjualanService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static Future<List<dynamic>> getLaporanPenjualan({
    int limit = 10,
    int offset = 0,
    String? startDate,
    String? endDate,
    String? nominalMin,
    String? nominalMax,
  }) async {
    String url = "$baseUrl/laporan-penjualan?limit=$limit&offset=$offset";

    if (startDate != null) url += "&start_date=$startDate";
    if (endDate != null) url += "&end_date=$endDate";
    if (nominalMin != null) url += "&nominal_min=$nominalMin";
    if (nominalMax != null) url += "&nominal_max=$nominalMax";

    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"]["items"];
    } else {
      throw Exception("Gagal ambil laporan penjualan");
    }
  }
}
