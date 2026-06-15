import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../service/penerimaan_service.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';
import '../../service/produk_service.dart';

class DetailPenerimaanScreen extends StatefulWidget {
  const DetailPenerimaanScreen({super.key});

  @override
  State<DetailPenerimaanScreen> createState() => _DetailPenerimaanScreenState();
}

class _DetailPenerimaanScreenState extends State<DetailPenerimaanScreen> {
  String? _idPenerimaan;
  bool _isLoading = true;

  String idPenerimaan = '';
  String tanggal = '';
  String idPembelian = '';
  String supplier = '';
  String totalHarga = '0';

  List<Map<String, dynamic>> details = [];

  List<dynamic> _suppliers = [];
  List<dynamic> _products = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_idPenerimaan == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      _idPenerimaan = args.toString();

      _fetchMasterData().then((_) => _fetchDetail());
    }
  }

  Future<void> _fetchMasterData() async {
    try {
      final results = await Future.wait([
        SupplierService.getAllSuppliers(limit: 999),
        ProdukService.getAllProduk(limit: 999),
      ]);
      if (mounted) {
        setState(() {
          _suppliers = results[0] as List<dynamic>;
          _products = results[1] as List<dynamic>;
        });
      }
    } catch (e) {
      // Tetap lanjut
    }
  }

  Future<void> _fetchDetail() async {
    try {
      final responseData = await PenerimaanService.getDetailPenerimaan(_idPenerimaan!);
      final body = responseData['data'] as Map<String, dynamic>? ?? responseData;
      final penerimaan = body['penerimaan'] ?? body;
      final idPembelianValue = penerimaan['id_pembelian']?.toString() ?? '';

      // Fetch supplier dari pembelian
      String namaSupplier = '-';
      try {
        final dataPembelian = await PembelianService.getDetailPembelian(idPembelianValue);
        final pembelian = dataPembelian['pembelian'] ?? dataPembelian;
        final supplierId = pembelian['id_supplier']?.toString() ?? '';
        try {
          final s = _suppliers.firstWhere((s) => s['id_supplier'].toString() == supplierId);
          namaSupplier = s['nama_supplier'] ?? supplierId;
        } catch (_) {
          namaSupplier = supplierId;
        }
      } catch (_) {}

      final rawDetails = body['details'] ?? [];
      final detailList = rawDetails.map((item) {
        final kode = item['kode_produk']?.toString() ?? '';
        String namaBarang = kode;
        try {
          final p = _products.firstWhere((p) => p['kode_produk'] == kode);
          namaBarang = p['nama_produk'] ?? kode;
        } catch (_) {}

        return {
          'nama_barang': namaBarang,
          'kode_batch': item['kode_batch_penerimaan']?.toString() ?? '-',
          'qty_pesan': item['quantity_dipesan'] ?? 0,
          'qty_terima': item['quantity_diterima'] ?? 0,
          'sisa_batch': item['quantity_sisa_barang_perbatch'] ?? 0,
          'keterangan': item['keterangan_barang']?.toString() ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          idPenerimaan = penerimaan['id_penerimaan']?.toString() ?? '';
          tanggal = _formatTanggal(penerimaan['tanggal_penerimaan']);
          idPembelian = idPembelianValue;
          supplier = namaSupplier;
          totalHarga = penerimaan['total_harga']?.toString() ?? '0';
          details = List<Map<String, dynamic>>.from(detailList);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
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
          const GlobalAppBar(title: 'Detail Penerimaan Barang'),
          const SizedBox(height: 15),

          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.penerimaan),
              icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1E293B)),
              label: const Text('Kembali', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                    // --- HEADER PENERIMAAN ---
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField(label: 'ID Penerimaan', value: idPenerimaan)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildReadOnlyField(label: 'Tanggal Terima', value: tanggal)),
                      ],
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildReadOnlyField(label: 'ID Pembelian (PO)', value: idPembelian)),
                        const SizedBox(width: 20),
                        Expanded(flex: 1, child: _buildReadOnlyField(label: 'Supplier', value: supplier)),
                      ],
                    ),

                    _buildReadOnlyField(label: 'Total Harga', value: _formatRupiah(num.tryParse(totalHarga) ?? 0)),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.grey, thickness: 0.5),
                    ),

                    const Text(
                      'Daftar Barang Diterima',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                    ),

                    const SizedBox(height: 15),

                    // --- HEADER TABEL ---
                    Row(
                      children: [
                        Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 2, child: Text('Kode Batch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: Text('Qty Pesan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: Text('Qty Terima', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: Text('Sisa Batch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 2, child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // --- LIST DETAIL ---
                    ...details.map((item) {
                      return _buildDetailRow(item);
                    }),

                    if (details.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text('Tidak ada data detail penerimaan.', style: TextStyle(color: Colors.grey)),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: TextEditingController(text: item['nama_barang'].toString()),
              readOnly: true,
              decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: TextField(
              controller: TextEditingController(text: item['kode_batch'].toString()),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: item['qty_pesan'].toString()),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                fillColor: Colors.blue.shade50,
              ),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 16),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: item['qty_terima'].toString()),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                fillColor: Colors.green.shade50,
              ),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: item['sisa_batch'].toString()),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                fillColor: Colors.orange.shade50,
              ),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 16),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: TextField(
              controller: TextEditingController(text: item['keterangan'].toString()),
              readOnly: true,
              maxLines: null,
              decoration: _inputStyle(readOnly: true).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
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
            decoration: _inputStyle(readOnly: true),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
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

  InputDecoration _inputStyle({bool readOnly = false}) {
    return InputDecoration(
      filled: true,
      fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: readOnly ? Colors.transparent : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: readOnly ? Colors.transparent : const Color(0xFF1E293B)),
      ),
    );
  }
}
