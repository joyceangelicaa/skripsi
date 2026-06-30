import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class PenjualanService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080/penjualan";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  // GET PENJUALAN BY CUSTOMER
  static Future<List<dynamic>> getPenjualanByCustomer({
    required int idCustomer,
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/customer/$idCustomer?limit=$limit&offset=$offset");
    final res = await http.get(uri, headers: _authHeaders());

    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      return result['data'] as List<dynamic>;
    } else {
      throw Exception('Gagal ambil penjualan by customer (${res.statusCode})');
    }
  }

  // GET ALL PENJUALAN
  static Future<List<Map<String, dynamic>>> getAllPenjualan({
    int limit = 10,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    String url = "$baseUrl?limit=$limit&offset=$offset";
    if (startDate != null && startDate.isNotEmpty) {
      url += "&start_date=$startDate";
    }
    if (endDate != null && endDate.isNotEmpty) {
      url += "&end_date=$endDate";
    } 

    final res = await http.get(
      Uri.parse(url),
      headers: _authHeaders(),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body);
      final List data = body['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } else {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal ambil penjualan");
    }
  }

  // GET DETAIL PENJUALAN
  static Future<List<Map<String, dynamic>>> getDetailPenjualan(String nomerPenjualan) async {
    final uri = Uri.parse("$baseUrl/$nomerPenjualan");
    final res = await http.get(
      uri,
      headers: _authHeaders(),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body);
      final List data = body['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    }

    final resBody = jsonDecode(res.body);
    throw Exception(resBody['message'] ?? "Gagal ambil detail penjualan");
  }

  // ADD PENJUALAN (HEADER ONLY) 
  static Future<String> addPenjualan({
    required int idCustomer,
    double potonganHarga = 0,
    String? tanggalPenjualan
  }) async {
    final body = <String, dynamic>{
    "id_customer": idCustomer,
    "potongan_harga": potonganHarga,
    };
    if (tanggalPenjualan != null && tanggalPenjualan.isNotEmpty) {
      body["tanggal_penjualan"] = tanggalPenjualan;
    }

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal tambah penjualan");
    }

    final resBody = jsonDecode(res.body);
    final data = resBody['data'];
    if (data == null || data['nomer_penjualan'] == null) {
      throw Exception("Response tidak mengandung nomer_penjualan: ${res.body}");
    }
    return data['nomer_penjualan'] as String;
  }

  // ADD DETAIL PENJUALAN
  static Future<List<String>> addDetailPenjualan(
  List<Map<String, dynamic>> details,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/detail"),
      headers: _authHeaders(),
      body: jsonEncode(details),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal tambah detail penjualan");
    }

    final resBody = jsonDecode(res.body);         
    final warnings = resBody['warnings'];       
    if (warnings != null && warnings is List) { 
      return warnings.cast<String>();             
    }
    return [];                                  
  }

  // EDIT PENJUALAN (HEADER ONLY)
  static Future<void> editPenjualan({
    required String nomerPenjualan,
    required int idCustomer,
    required double potonganHarga,
  }) async {
    final body = {
      "nomer_penjualan": nomerPenjualan,
      "id_customer": idCustomer,
      "potongan_harga": potonganHarga,
    };

    final res = await http.put(
      Uri.parse(baseUrl),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal edit penjualan");
    }
  }

  // EDIT DETAIL PENJUALAN
  static Future<void> editDetailPenjualan({
    required String nomerPenjualan,
    required List<Map<String, dynamic>> details,
  }) async {
    final body = {
      "nomer_penjualan": nomerPenjualan,
      "detail_penjualan": details,
    };

    final res = await http.put(
      Uri.parse("$baseUrl/detail_penjualan"),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal edit detail penjualan");
    }
  }

  // DELETE DETAIL PENJUALAN
  static Future<void> deleteDetailPenjualan(int idDetailPenjualan) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/detail/$idDetailPenjualan"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal hapus detail penjualan");
    }
  }

  // DELETE PENJUALAN
  static Future<void> deletePenjualan(String nomerPenjualan) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/$nomerPenjualan"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      final resBody = jsonDecode(res.body);
      throw Exception(resBody['message'] ?? "Gagal hapus penjualan");
    }
  }
}
