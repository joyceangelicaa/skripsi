import 'dart:typed_data';

import 'pdf_download_helper.dart' as pdf_helper;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LaporanPenjualanPdfService {
  static Future<Uint8List> generateLaporanPenjualanPdf({
    required List<Map<String, dynamic>> items,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                'DATA PENJUALAN',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (startDate != null && endDate != null) ...[
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Periode: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                  ),
                  children: ['No', 'No Transaksi', 'Tanggal', 'Nama Customer', 'Total Harga']
                      .map((h) => pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final customer = item['customer'] is Map
                      ? (item['customer'] as Map)['nama_customer']?.toString() ?? '-'
                      : item['nama_customer']?.toString() ?? '-';
                  return pw.TableRow(
                    children: [
                      '${index + 1}',
                      item['nomer_penjualan']?.toString() ?? '-',
                      _formatDate(item['tanggal_penjualan']),
                      customer,
                      _formatRupiah(item['total_harga']),
                    ].map((c) => pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(c, style: const pw.TextStyle(fontSize: 8)),
                        )).toList(),
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static void downloadPdf(Uint8List bytes, String filename) {
    pdf_helper.downloadPdf(bytes, filename);
  }

  static String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return date;
    }
  }

  static String _formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    final str = number.toStringAsFixed(0).split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}