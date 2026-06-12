// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // ⚠️ Import ini hanya akan dipakai saat Web
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

// class StorageHelper {
//   // ========================
//   // SIMPAN DATA
//   // ========================
//   static Future<void> save(String key, String value) async {
//     if (kIsWeb) {
//       html.window.localStorage[key] = value;
//     } else {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(key, value);
//     }
//   }

//   // ========================
//   // AMBIL DATA
//   // ========================
//   static Future<String?> get(String key) async {
//     if (kIsWeb) {
//       return html.window.localStorage[key];
//     } else {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getString(key);
//     }
//   }

//   // ========================
//   // HAPUS DATA
//   // ========================
//   static Future<void> remove(String key) async {
//     if (kIsWeb) {
//       html.window.localStorage.remove(key);
//     } else {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove(key);
//     }
//   }
// }

export 'storage_helper_mobile.dart'
    if (dart.library.html) 'storage_helper_web.dart';