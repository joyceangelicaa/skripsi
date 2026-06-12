import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../service/penjualan_service.dart';
import '../../service/customer_service.dart';
import '../../service/produk_service.dart';
import '../../service/nota_pdf_service.dart';

class ViewTransaksiScreen extends StatefulWidget {
  final Map<String, dynamic>? penjualanData;
  const ViewTransaksiScreen({super.key, this.penjualanData});

  @override
  State<ViewTransaksiScreen> createState() => _ViewTransaksiScreenState();
}

class _ViewTransaksiScreenState extends State<ViewTransaksiScreen> {
  List<Map<String, dynamic>> _details = [];
  List<dynamic> _produkList = [];
  String _nomerTransaksi = '';
  String _tanggal = '';
  String _customer = '';
  double _subtotal = 0;
  double _diskon = 0;
  double _totalAkhir = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = widget.penjualanData;
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      _nomerTransaksi = data['nomer_penjualan'] ?? '';
      _tanggal = _formatDate(data['tanggal_penjualan']);
      _subtotal = (data['subtotal'] ?? 0).toDouble();
      _diskon = (data['potongan_harga'] ?? 0).toDouble();
      _totalAkhir = (data['total_harga'] ?? 0).toDouble();

      String namaCustomer = data['customer']?['nama_customer'] ?? data['nama_customer'] ?? '';
      if (namaCustomer.isEmpty && data['id_kustomer'] != null) {
        try {
          final idCust = data['id_kustomer'] is int
              ? data['id_kustomer']
              : int.tryParse(data['id_kustomer'].toString()) ?? 0;
          if (idCust > 0) {
            final cust = await CustomerService.getDetailCustomer(idCust);
            namaCustomer = cust['nama_customer'] ?? '';
          }
        } catch (_) {}
      }
      _customer = namaCustomer;

      final detailList = await PenjualanService.getDetailPenjualan(_nomerTransaksi);
      _details = detailList;

      final produkData = await ProdukService.getAllProduk(limit: 999, offset: 0);
      _produkList = produkData;

      // hitung ulang subtotal dari detail
      double calcSubtotal = 0;
      for (var d in _details) {
        calcSubtotal += (d['total_harga_detail'] ?? 0).toDouble();
      }
      _subtotal = calcSubtotal;
      _totalAkhir = _subtotal - _diskon;

      setState(() => _isLoading = false);
    } catch (e) {
      print("ERROR VIEW TRANSAKSI: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return date;
    }
  }

  String _formatRupiah(num value) {
    final str = value.toStringAsFixed(0).split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _getNamaProduk(String kode) {
    try {
      final p = _produkList.firstWhere((p) => p['kode_produk'] == kode);
      return p is Map<String, dynamic> ? p['nama_produk'] ?? '' : kode;
    } catch (_) {
      return kode;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Detail Transaksi'),
          const SizedBox(height: 15),

          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/transaksi'),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 18),
              label: const Text(
                'Kembali',
                style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField(label: 'Nomor Transaksi', value: _nomerTransaksi)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildReadOnlyField(label: 'Tanggal Transaksi', value: _tanggal)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildReadOnlyField(label: 'Nama Customer', value: _customer)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 2, child: Text('Harga Satuan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 2, child: Text('Total Harga', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Column(
                      children: _details.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: _buildDisabledInput(d['quantity'].toString(), isCenter: true)),
                              const SizedBox(width: 15),
                              Expanded(flex: 3, child: _buildDisabledInput(_getNamaProduk(d['kode_produk'] ?? ''))),
                              const SizedBox(width: 15),
                              Expanded(flex: 2, child: _buildDisabledInput(_formatRupiah((d['harga_jual'] ?? 0).toDouble()))),
                              const SizedBox(width: 15),
                              Expanded(flex: 2, child: _buildDisabledInput(_formatRupiah((d['total_harga_detail'] ?? 0).toDouble()))),
                              const SizedBox(width: 40),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 350,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Harga', style: TextStyle(fontSize: 16)),
                                Text(_formatRupiah(_subtotal), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Diskon (Rp)', style: TextStyle(fontSize: 16)),
                                SizedBox(
                                  width: 150,
                                  height: 40,
                                  child: TextField(
                                    controller: TextEditingController(text: _formatRupiah(_diskon)),
                                    readOnly: true,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade200,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Akhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(_formatRupiah(_totalAkhir), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Menyiapkan dokumen...'), backgroundColor: Colors.green),
                                    );

                                    final pdfBytes = await NotaPdfService.generateNotaPdf(
                                      nomerTransaksi: _nomerTransaksi,
                                      tanggal: _tanggal,
                                      customer: _customer,
                                      details: _details,
                                      subtotal: _subtotal,
                                      diskon: _diskon,
                                      totalAkhir: _totalAkhir,
                                      getNamaProduk: (kode) => _getNamaProduk(kode),
                                    );

                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                    final filename = 'nota_penjualan_$_nomerTransaksi.pdf';
                                    NotaPdfService.downloadPdf(pdfBytes, filename);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Nota berhasil diunduh: $filename'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal mencetak nota: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.print_outlined),
                                label: const Text('Cetak Nota'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: true,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            decoration: _inputStyle(readOnly: true),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle({bool readOnly = false}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildDisabledInput(String text, {bool isCenter = false, String prefix = ''}) {
    return TextField(
      controller: TextEditingController(text: text),
      readOnly: true,
      textAlign: isCenter ? TextAlign.center : TextAlign.left,
      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
