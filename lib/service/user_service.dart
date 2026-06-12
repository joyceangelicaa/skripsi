import 'dart:convert';
// import 'dart:html' as html;
import 'storage_helper.dart';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'https://skripsi.crossnet.co.id:8080/user';
  static const String baseLogin = 'https://skripsi.crossnet.co.id:8080/login';

  static String? token;
  static int? idUser;
  static String? namaUser;
  static String? role;
  static String? email;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse(baseLogin),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      token = body['data']['token'];
      saveToken(token!);

      idUser = body['data']['id_user'];
      namaUser = body['data']['nama_user'] ?? '';
      role = body['data']['role'] ?? '';
      email = body['data']['email'] ?? '';

      // if (idUser != null) {
      //   html.window.localStorage['id_user'] = idUser.toString();
      // }
      // if (namaUser != null && namaUser!.isNotEmpty) {
      //   html.window.localStorage['nama_user'] = namaUser!;
      // }
      // if (role != null && role!.isNotEmpty) {
      //   html.window.localStorage['role'] = role!;
      // }

      if (idUser != null) {
        await StorageHelper.save('id_user', idUser.toString());
      }

      if (namaUser != null && namaUser!.isNotEmpty) {
        await StorageHelper.save('nama_user', namaUser!);
      }

      if (role != null && role!.isNotEmpty) {
        await StorageHelper.save('role', role!);
      }

      if (email != null && email!.isNotEmpty) {
        await StorageHelper.save('email', email!);
      }

      return body['data'];
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal login');
    }
  }

  static Future<List<dynamic>> getAllUsers({
      int limit = 10,
    int offset = 0,
  }) async {
    final response = await http
        .get(
          // Uri.parse(baseUrl),
          Uri.parse("$baseUrl?limit=$limit&offset=$offset"),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal load user (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getDetailUser(int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/$id'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal load detail user');
    }
  }

  static Future<void> addUser(Map<String, dynamic> data) async {
    final response = await http
        .post(
          Uri.parse(baseUrl),
          headers: await _authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal tambah user';
      throw Exception(msg);
    }
  }

  static Future<void> editUser(Map<String, dynamic> data) async {
    final response = await http
        .put(
          Uri.parse(baseUrl),
          headers: await _authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.body.isNotEmpty ? response.body : 'Gagal edit user';
      throw Exception(msg);
    }
  }

  static Future<void> deleteUser(int id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/$id'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal hapus user (${response.statusCode})');
    }
  }

  // === TOKEN & USER DATA MANAGEMENT ===

  // Ambil token dari localStorage -> simpan ke memory (UserService.token)
  // Biar gak ilang pas hot reload
  static Future<void> loadToken() async {
    final saved = await StorageHelper.get('token');
    if (saved != null && saved.isNotEmpty) {
      token = saved;
    }
  }

  static Future<void> loadUserData() async {
    final savedId = await StorageHelper.get('id_user');
    if (savedId != null && savedId.isNotEmpty) {
      idUser = int.tryParse(savedId);
    }

    final savedName = await StorageHelper.get('nama_user');
    if (savedName != null && savedName.isNotEmpty) {
      namaUser = savedName;
    }

    final savedRole = await StorageHelper.get('role');
    if (savedRole != null && savedRole.isNotEmpty) {
      role = savedRole;
    }

    final savedEmail = await StorageHelper.get('email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      email = savedEmail;
    }
  }

  // Simpan token ke memory (UserService.token) + cadangkan ke localStorage
  static Future<void> saveToken(String tokenValue) async {
    token = tokenValue;
    await StorageHelper.save('token', tokenValue);
  }

  // Hapus token dari memory + localStorage
  static Future<void> clearToken() async {
    token = null;
    idUser = null;
    namaUser = null;
    role = null;
    email = null;

    await StorageHelper.remove('token');
    await StorageHelper.remove('id_user');
    await StorageHelper.remove('nama_user');
    await StorageHelper.remove('role');
    await StorageHelper.remove('email');
  }

  static Future<Map<String, String>> _authHeaders() async {
    if (token == null) await loadToken();

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }
}
