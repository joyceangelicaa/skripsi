import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Digunakan di MOBILE/DESKTOP: simpan PDF ke folder temporary, lalu buka share sheet
void downloadPdf(Uint8List bytes, String filename) async {
  // Ambil folder temporary HP
  final dir = await getTemporaryDirectory();
  // Buat file PDF
  final file = File('${dir.path}/$filename');
  // Tulis bytes ke file
  await file.writeAsBytes(bytes);
  // Buka share sheet biar user bisa simpan/share file
  await Share.shareXFiles([XFile(file.path)], text: filename);
}
