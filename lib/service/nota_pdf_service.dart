import 'dart:typed_data';

import 'pdf_download_helper.dart' as pdf_helper;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NotaPdfService {
  static Future<Uint8List> generateNotaPdf({
    required String nomerTransaksi,
    required String tanggal,
    required String customer,
    required List<Map<String, dynamic>> details,
    required double subtotal,
    required double diskon,
    required double totalAkhir,
    String? Function(String kodeProduk)? getNamaProduk,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
         pageFormat: PdfPageFormat(125.0 * PdfPageFormat.mm, 176.0 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderRow('Nomor Transaksi', nomerTransaksi,
                  'Tanggal Transaksi', tanggal, 'Customer', customer),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Tabel
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(165),
                  2: const pw.FixedColumnWidth(65),
                  3: const pw.FixedColumnWidth(70),
                },
                headers: ['Qty', 'Nama Barang', 'Harga', 'Total'],
                data: details.map((d) {
                  final qty = d['quantity']?.toString() ?? '0';
                  final kode = d['kode_produk'] ?? '';
                  final nama = getNamaProduk != null ? getNamaProduk(kode) : kode;
                  final harga = d['harga_jual']?.toString() ?? '0';
                  final total = d['total_harga_detail']?.toString() ?? '0';
                  return [qty, nama, harga, 'Rp $total'];
                }).toList(),
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Footer
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildFooterRow('Total Harga', _formatRupiah(subtotal),
                        false),
                    pw.SizedBox(height: 6),
                    _buildFooterRow('Diskon', _formatRupiah(diskon), false),
                    pw.SizedBox(height: 6),
                    _buildFooterRow(
                        'Total Akhir', _formatRupiah(totalAkhir), true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderRow(
    String label1, String value1,
    String label2, String value2,
    String label3, String value3,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label1,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(value1,
                  style:
                      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label2,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(value2,
                  style:
                      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label3,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(value3,
                  style:
                      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooterRow(String label, String value, bool isTotal) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.left,
          ),
        ),
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: pw.FontWeight.bold,
              color: isTotal
                  ? PdfColor.fromInt(0xFF1E293B)
                  : PdfColors.black,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Download PDF — otomatis pakai cara sesuai platform (web via AnchorElement, mobile via share)
  static void downloadPdf(Uint8List bytes, String filename) {
    pdf_helper.downloadPdf(bytes, filename);
  }

  static String _formatRupiah(double value) {
    return 'Rp ${value.toStringAsFixed(0)}';
  }
}
