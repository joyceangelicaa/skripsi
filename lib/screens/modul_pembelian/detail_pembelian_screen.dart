import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';
import '../../service/produk_service.dart';

class DetailPembelianScreen extends StatefulWidget {
  const DetailPembelianScreen({super.key});

  @override
  State<DetailPembelianScreen> createState() => _DetailPembelianScreenState();
}

class _DetailPembelianScreenState extends State<DetailPembelianScreen> {
  String? _idPembelian;
  bool _isLoading = true;

  String idPembelian = '';
  String tanggal = '';
  String supplier = '';
  String leadTime = '-';
  String totalHarga = '0';

  List<Map<String, dynamic>> items = [];

  List<dynamic> _suppliers = [];
  List<dynamic> _products = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_idPembelian == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      _idPembelian = args.toString();

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
      // Tetap lanjut — detail akan tampil dengan ID/kode apa adanya
    }
  }

  // =========================
  // GET DETAIL API (LOGIKA TIDAK DIUBAH)
  // =========================
  Future<void> _fetchDetail() async {
    try {
      final data = await PembelianService.getDetailPembelian(_idPembelian!);

      final pembelian = data['pembelian'] ?? data;

      final supplierId = pembelian['id_supplier']?.toString() ?? '';

      String namaSupplier = supplierId;
      String leadValue = '-';
      try {
        final s = _suppliers.firstWhere((s) => s['id_supplier'].toString() == supplierId);
        namaSupplier = s['nama_supplier'] ?? supplierId;
        leadValue = '${s['lead_time'] ?? '-'} Hari';
      } catch (_) {}

      final details = data['details'] ?? [];

      final itemList = details.map((item) {
        final kode = item['kode_produk']?.toString() ?? '';

        String namaBarang = kode;
        int rekomendasi = 0;
        try {
          final p = _products.firstWhere((p) => p['kode_produk'] == kode);
          namaBarang = p['nama_produk'] ?? kode;

          final rop = (p['reorder_point'] ?? 0) as int;
          final stok = (p['stok_produk'] ?? 0) as int;
          final safety = (p['safety_stock'] ?? 0) as int;
          if (stok > rop) {
            rekomendasi = 0;
          } else {
            rekomendasi = rop - stok + safety;
            if (rekomendasi < 0) rekomendasi = 0;
          }
        } catch (_) {}

        return {
          'nama_barang': namaBarang,
          'harga': item['harga_beli'] ?? 0,
          'rekomendasi': rekomendasi,
          'qty': item['quantity'] ?? 0,
        };
      }).toList();

      setState(() {
        idPembelian = pembelian['id_pembelian'].toString();
        tanggal = PembelianService.formatDate(pembelian['tanggal_pembelian']);
        supplier = namaSupplier;
        leadTime = leadValue;
        totalHarga = pembelian['total_harga']?.toString() ?? '0';
        items = List<Map<String, dynamic>>.from(itemList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
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
          const GlobalAppBar(title: 'Detail Pembelian'),
          const SizedBox(height: 15),

          // Tombol Kembali
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.pembelian),
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
                    // --- HEADER PEMBELIAN ---
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField(label: 'ID Pembelian', value: idPembelian)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildReadOnlyField(label: 'Tanggal Pembelian', value: tanggal)),
                      ],
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildReadOnlyField(label: 'Nama Supplier', value: supplier)),
                        const SizedBox(width: 20),
                        Expanded(flex: 1, child: _buildReadOnlyField(label: 'Lead Time', value: leadTime)),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.grey, thickness: 0.5),
                    ),

                    const Text(
                      'Daftar Barang Pesanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                    ),

                    const SizedBox(height: 15),

                    // --- HEADER TABEL ---
                    Row(
                      children: [
                        Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 12),
                        Expanded(flex: 1, child: Text('Harga Beli', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 12),
                        Expanded(flex: 1, child: Text('Rekomendasi Pembelian', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 12),
                        Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // --- LIST BARANG ---
                    ...items.map((item) {
                      return _buildItemRow(item);
                    }),
                    
                    const SizedBox(height: 20),
                    // --- TOTAL HARGA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Total Harga: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_formatRupiah(num.tryParse(totalHarga) ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300, thickness: 1),
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

  String _formatRupiah(num value) {
    final str = value.toStringAsFixed(0).split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  // =========================
  // HELPER UI
  // =========================

  Widget _buildItemRow(Map<String, dynamic> item) {
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
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: _formatRupiah(num.tryParse(item['harga'].toString()) ?? 0)),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: '${item['rekomendasi'] ?? 0}'),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: item['qty'].toString()),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
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