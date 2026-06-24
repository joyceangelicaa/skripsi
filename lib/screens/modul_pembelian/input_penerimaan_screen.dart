import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../service/penerimaan_service.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';
import '../../service/produk_service.dart';
// import '../../service/kartu_stok_service.dart';

class InputPenerimaanScreen extends StatefulWidget {
  const InputPenerimaanScreen({super.key});

  @override
  State<InputPenerimaanScreen> createState() => _InputPenerimaanScreenState();
}

class _InputPenerimaanScreenState extends State<InputPenerimaanScreen> {
  String? _idPembelianArgs;
  bool _isLoading = true;

  DateTime _tanggalPenerimaan = DateTime.now();
  String idPembelian = '';
  String supplier = '';
  String totalHarga = '0';

  List<Map<String, dynamic>> items = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var item in items) {
      (item['terima_controller'] as TextEditingController?)?.dispose();
      (item['keterangan_controller'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_idPembelianArgs == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      _idPembelianArgs = args.toString();
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
    } catch (_) {}
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await PembelianService.getDetailPembelian(_idPembelianArgs!);
      final pembelian = data['pembelian'] ?? data;

      final supplierId = pembelian['id_supplier']?.toString() ?? '';
      String namaSupplier = supplierId;
      try {
        final s = _suppliers.firstWhere((s) => s['id_supplier'].toString() == supplierId);
        namaSupplier = s['nama_supplier'] ?? supplierId;
      } catch (_) {}

      final details = data['details'] ?? [];
      final itemList = details.map((item) {
        final kode = item['kode_produk']?.toString() ?? '';
        String namaBarang = kode;
        try {
          final p = _products.firstWhere((p) => p['kode_produk'] == kode);
          namaBarang = p['nama_produk'] ?? kode;
        } catch (_) {}

        return {
          'kode_produk': kode,
          'nama_barang': namaBarang,
          'harga': item['harga_beli'] ?? 0,
          'qty': item['quantity'] ?? 0,
          'total_diterima': item['total_diterima'] ?? 0,
        };
      }).toList();

      setState(() {
        idPembelian = pembelian['id_pembelian'].toString();
        final rawTgl = pembelian['tanggal_pembelian'];
        if (rawTgl != null) {
          _tanggalPenerimaan = DateTime.tryParse(rawTgl) ?? DateTime.now();
        }
        supplier = namaSupplier;
        totalHarga = pembelian['total_harga']?.toString() ?? '0';
        items = List<Map<String, dynamic>>.from(itemList);
        for (var item in items) {
          item['terima_controller'] = TextEditingController();
          item['keterangan_controller'] = TextEditingController();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _batal() async {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
    }
  }

  // ================== VALIDASI ==================
  String? _validate() {
    bool adaTerima = false;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final qty = (item['qty'] as num).toInt();
      final diterima = (item['total_diterima'] as num).toInt();
      final terima = int.tryParse((item['terima_controller'] as TextEditingController).text) ?? 0;
      final sisa = qty - diterima;

      if (terima > 0) adaTerima = true;

      if (terima > sisa) {
        final keterangan = (item['keterangan_controller'] as TextEditingController).text.trim();
        if (keterangan.isEmpty) {
          return 'Baris ${i + 1}: Keterangan wajib diisi karena jumlah terima ($terima) melebihi sisa ($sisa)';
        }
      }
    }
    if (!adaTerima) return 'Minimal satu baris harus diisi jumlah terima';
    return null;
  }

  // ================== HANDLE SIMPAN (VALIDASI → KONFIRMASI → POST) ==================
  Future<void> _handleSimpan() async {
    final error = _validate();
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah data penerimaan sudah benar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
            child: const Text('Ya', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _submitPenerimaan();
  }

  // ================== SUBMIT (POST SAJA) ==================
  Future<void> _submitPenerimaan() async {
    try {
      if (_idPembelianArgs == null) {
        throw Exception("ID Pembelian tidak ditemukan");
      }

      // Hitung total_harga dari qty_terima × harga_beli
      int totalTerima = 0;
      List<Map<String, dynamic>> details = [];
      for (var item in items) {
        final terima = int.tryParse((item['terima_controller'] as TextEditingController).text) ?? 0;
        if (terima == 0) continue;
        final harga = (item['harga'] as num).toDouble();
        totalTerima += (terima * harga).toInt();
        details.add({
          "kode_produk": item['kode_produk'],
          "quantity_dipesan": (item['qty'] as num).toInt(),
          "quantity_diterima": terima,
          "kode_batch_penerimaan": null,
          "keterangan_barang": (item['keterangan_controller'] as TextEditingController).text,
        });
      }

      // 1. POST header dengan total yang benar
      final formattedTgl = '${_tanggalPenerimaan.year}-${_tanggalPenerimaan.month.toString().padLeft(2, '0')}-${_tanggalPenerimaan.day.toString().padLeft(2, '0')}';
      final idPenerimaan = await PenerimaanService.addPenerimaan(
        idPembelian: _idPembelianArgs!,
        totalHarga: totalTerima,
        tanggalPenerimaan: formattedTgl,
      );

      // 2. POST details
      final detailPayload = details.map((d) => {
        'id_penerimaan': idPenerimaan,
        'kode_produk': d['kode_produk'],
        'quantity_dipesan': d['quantity_dipesan'],
        'quantity_diterima': d['quantity_diterima'],
        'kode_batch_penerimaan': null,
        'keterangan_barang': d['keterangan_barang'],
      }).toList();

      await PenerimaanService.addDetailPenerimaan(detailPayload);

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Barang Berhasil Diterima!',
          message: 'Data penerimaan barang telah dicatat dan stok gudang otomatis bertambah.',
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ConfirmationDialog(
          isSuccess: false,
          title: 'Gagal!',
          message: e.toString(),
        ),
      );
    }
  }

  // ================== UI ==================
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
          const GlobalAppBar(title: 'Input Penerimaan Barang'),
          const SizedBox(height: 15),
          OutlinedButton.icon(
                            onPressed: _batal,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 18),
            label: const Text('Kembali', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildReadOnlyField(label: 'ID Pembelian (PO)', value: idPembelian)),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: _buildDatePickerField(
                              label: 'Tanggal Terima',
                              selectedDate: _tanggalPenerimaan,
                              onChanged: (date) => setState(() => _tanggalPenerimaan = date),
                            )),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: _buildReadOnlyField(label: 'Supplier', value: supplier)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- DATA PENERIMAAN BARANG ---
                  Container(
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
                        const Text(
                          'Data Penerimaan Barang',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Diterima', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Terima', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 3, child: Text('Keterangan Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: TextEditingController(text: item['nama_barang']),
                                    readOnly: true,
                                    decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: TextEditingController(text: _formatRupiah((item['harga'] as num).toDouble())),
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
                                    controller: TextEditingController(text: item['qty'].toString()),
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
                                    controller: TextEditingController(text: item['total_diterima'].toString()),
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: _inputStyle(readOnly: true).copyWith(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      fillColor: Colors.orange.shade50,
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: item['terima_controller'],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: _inputStyle().copyWith(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      hintText: '0',
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.green, width: 2),
                                      ),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: item['keterangan_controller'],
                                    decoration: _inputStyle().copyWith(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      hintText: 'Catatan...',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
              onPressed: _batal,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton(
                              onPressed: _handleSimpan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Simpan Data Penerimaan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildDatePickerField({
  required String label,
  required DateTime selectedDate,
  required ValueChanged<DateTime> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
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

  InputDecoration _inputStyle({bool readOnly = false}) {
    return InputDecoration(
      filled: true,
      fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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