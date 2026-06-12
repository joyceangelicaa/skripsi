import 'dart:typed_data';

import 'pdf_download_helper.dart' as pdf_helper;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LaporanPenjualanPdfService {
  static Future<Uint8List> generateLaporanPenjualanPdf({
    required List<dynamic> items,
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
                'LAPORAN PENJUALAN',
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
                5: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                  ),
                  children: ['No', 'No Penjualan', 'Tanggal', 'Nama Customer', 'Jumlah Produk', 'Total Penjualan']
                      .map((h) => pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final cells = [
                    '${index + 1}',
                    item["nomer_penjualan"] ?? '-',
                    _formatDate(item["tanggal_penjualan"]),
                    item["nama_customer"] ?? '-',
                    '${item["jumlah_produk_dipesan"] ?? 0}',
                    'Rp ${item["total_harga"]}',
                  ];
                  return pw.TableRow(
                    children: cells.map((c) => pw.Container(
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

  // Download PDF — otomatis pakai cara sesuai platform (web via AnchorElement, mobile via share)
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

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
