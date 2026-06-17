import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class DashboardService {
  static const String baseUrl = "https://skripsi.crossnet.co.id:8080/dashboard";

  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      if (UserService.token != null) "Authorization": "Bearer ${UserService.token}",
    };
  }

  static String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static Future<double> getPendapatan({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/pendapatan?start_date=${_fmtDate(startDate)}&end_date=${_fmtDate(endDate)}");
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      return (result['data']['total_pendapatan'] as num).toDouble();
    }
    throw Exception('Gagal ambil pendapatan (${res.statusCode})');
  }

  static Future<double> getPengeluaran({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/pengeluaran?start_date=${_fmtDate(startDate)}&end_date=${_fmtDate(endDate)}");
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      return (result['data']['total_pengeluaran'] as num).toDouble();
    }
    throw Exception('Gagal ambil pengeluaran (${res.statusCode})');
  }

  static Future<Map<String, int>> getStatusPembelian({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/pembelian?start_date=${_fmtDate(startDate)}&end_date=${_fmtDate(endDate)}");
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      final data = result['data'];
      return {
        'baru': data['pembelian_baru'] as int,
        'proses': data['pembelian_proses'] as int,
        'selesai': data['pembelian_selesai'] as int,
      };
    }
    throw Exception('Gagal ambil status pembelian (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> getProdukTerlaris({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/produk/terlaris?start_date=${_fmtDate(startDate)}&end_date=${_fmtDate(endDate)}");
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      return (result['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Gagal ambil produk terlaris (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> getPenjualanHarian({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(
        "$baseUrl/penjualan?start_date=${_fmtDate(startDate)}&end_date=${_fmtDate(endDate)}");
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      return (result['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Gagal ambil penjualan harian (${res.statusCode})');
  }
}
