import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';
import '../../service/produk_service.dart';

class InputPembelianScreen extends StatefulWidget {
  const InputPembelianScreen({super.key});

  @override
  State<InputPembelianScreen> createState() => _InputPembelianState();
}

class _InputPembelianState extends State<InputPembelianScreen> {
  String get _tanggalDisplay {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  int get _totalHarga {
    int total = 0;
    for (var item in _listBarang) {
      final qtyText = item['qty_controller']?.text ?? '';
      final hargaText = item['harga_controller']?.text ?? '';
      if (qtyText.isNotEmpty && hargaText.isNotEmpty) {
        total += (int.tryParse(qtyText) ?? 0) * (int.tryParse(hargaText) ?? 0);
      }
    }
    return total;
  }

  bool _isSaving = false;

  // 2. State untuk Supplier
  String? _selectedSupplierId;
  List<dynamic> _suppliers = [];

  // 3. State untuk Produk
  List<dynamic> _products = [];
  bool _isLoadingMaster = true;

  // 4. State untuk Daftar Barang Dinamis
  final List<Map<String, dynamic>> _listBarang = [
    {
      'kode_produk': null,
      'barang': '',
      'qty_controller': TextEditingController(),
      'harga_controller': TextEditingController(),
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  Future<void> _fetchMasterData() async {
    try {
      final results = await Future.wait([
        SupplierService.getAllSuppliers(limit: 999),
        ProdukService.getAllProduk(limit: 999),
      ]);
      setState(() {
        _suppliers = results[0] as List<dynamic>;
        _products = results[1] as List<dynamic>;
        _isLoadingMaster = false;
      });
    } catch (e) {
      setState(() => _isLoadingMaster = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal muat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var barang in _listBarang) {
      barang['qty_controller']?.dispose();
      barang['harga_controller']?.dispose();
    }
    super.dispose();
  }

  void _tambahBarang() {
    setState(() {
      _listBarang.add({
        'kode_produk': null,
        'barang': '',
        'qty_controller': TextEditingController(),
        'harga_controller': TextEditingController(),
      });
    });
  }

  void _hapusBarang(int index) {
    setState(() {
      _listBarang[index]['qty_controller']?.dispose();
      _listBarang[index]['harga_controller']?.dispose();
      _listBarang.removeAt(index);
    });
  }

  // // =========================
  // // GENERATE ID + BATAL
  // // =========================
  // Future<void> _generateIdPembelian(int idSupplier) async {
  //   if (_generatedIdPembelian != null) return;
  //   try {
  //     final id = await PembelianService.addPembelian(idSupplier: idSupplier);
  //     if (mounted) setState(() => _generatedIdPembelian = id);
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Gagal generate ID: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   }
  // }

  Future<void> _batal() async {
    // if (_generatedIdPembelian != null) {
    //   await PembelianService.deletePembelian(_generatedIdPembelian!);
    // }
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
    }
  }

  // =========================
  // FUNGSI SIMPAN KE API
  // =========================
  Future<void> _simpanPembelian() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // VALIDASI
      if (_selectedSupplierId == null) {
        throw Exception("Supplier harus dipilih");
      }

      int idSupplier = int.parse(_selectedSupplierId!);

      // build detail
      List<Map<String, dynamic>> details = [];
      int total = 0;

      for (var item in _listBarang) {
        if (item['kode_produk'] == null) continue;

        final qtyText = item['qty_controller']?.text ?? '';
        if (qtyText.isEmpty) continue;

        final hargaText = item['harga_controller']?.text ?? '';
        int qty = int.parse(qtyText);
        int harga = int.tryParse(hargaText) ?? 0;
        total += qty * harga;

        details.add({
          "kode_produk": item['kode_produk'],
          "quantity": qty,
          "harga_beli": harga,
        });
      }

      if (details.isEmpty) {
        throw Exception("Minimal 1 barang harus diisi dengan QTY");
      }

      if (total == 0) {
        throw Exception("Total harga harus lebih dari 0. Isi QTY dan Harga dengan benar");
      }

      // if (_generatedIdPembelian == null) {
      //   throw Exception("ID Pembelian belum digenerate, pilih supplier terlebih dahulu");
      // }

      final generatedId = await PembelianService.addPembelian(idSupplier: idSupplier);

      final detailPayload = details.map((d) => {
        'id_pembelian': generatedId,
        'kode_produk': d['kode_produk'],
        'quantity': d['quantity'],
        'harga_beli': d['harga_beli'],
      }).toList();

      await PembelianService.addDetailPembelian(detailPayload);

      // SUCCESS - Munculkan Dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'PO Berhasil Dibuat!',
          message: 'Data pembelian beserta daftar barang berhasil disimpan.',
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoute.pembelian);

    } catch (e) {
      print("ERROR _simpanPembelian: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMaster) {
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
          const GlobalAppBar(title: 'Input Pembelian Baru (PO)'),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _batal,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 18),
              label: const Text('Kembali', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
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
                    // --- HEADER PEMBELIAN ---
                    _buildReadOnlyField(label: 'Tanggal Pembelian', value: _tanggalDisplay),
                    _buildSupplierDropdown(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.grey, thickness: 0.5),
                    ),
                    // --- JUDUL & TOMBOL INPUT BARANG ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Barang Pesanan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _tambahBarang,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Input Barang', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // --- HEADER TABEL ---
                    Row(
                      children: [
                        Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: Text('Hrg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        const SizedBox(width: 58),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_listBarang.length, (index) {
                      return _buildItemRow(index);
                    }),
                    const SizedBox(height: 20),
                    // --- TOTAL HARGA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Total Harga: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_formatRupiah(_totalHarga),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 20),
                    // --- TOMBOL AKSI ---
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
                          onPressed: _isSaving ? null : _simpanPembelian,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Simpan Data Pembelian'),
                        ),
                      ],
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

  // ==========================================
  // --- WIDGET HELPER UI LAMA (TIDAK DIUBAH) ---
  // ==========================================

  Widget _buildSupplierDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _suppliers.map((s) => s['nama_supplier']?.toString() ?? '')
                    .where((n) => n.isNotEmpty);
              }
              final query = textEditingValue.text.toLowerCase();
              return _suppliers.map((s) => s['nama_supplier']?.toString() ?? '')
                  .where((n) => n.isNotEmpty && n.toLowerCase().contains(query));
            },
            onSelected: (selection) {
              final match = _suppliers.firstWhere((s) => s['nama_supplier'] == selection);
              setState(() {
                _selectedSupplierId = match['id_supplier'].toString();
              });
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: _inputStyle().copyWith(
                  hintText: 'Cari nama supplier...',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    var item = _listBarang[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _products.map((p) => p['nama_produk']?.toString() ?? '')
                      .where((n) => n.isNotEmpty);
                }
                final query = textEditingValue.text.toLowerCase();
                return _products.map((p) => p['nama_produk']?.toString() ?? '')
                    .where((n) => n.isNotEmpty && n.toLowerCase().contains(query));
              },
              onSelected: (selection) {
                final match = _products.firstWhere((p) => p['nama_produk'] == selection);
                setState(() {
                  item['kode_produk'] = match['kode_produk'];
                  item['barang'] = selection;
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: _inputStyle().copyWith(
                    hintText: 'Cari Barang...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onChanged: (val) {
                    item['barang'] = val;
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: item['harga_controller'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: _inputStyle().copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), hintText: '0', prefixText: 'Rp '),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: item['qty_controller'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: _inputStyle().copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), hintText: '0'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _hapusBarang(index),
              icon: const Icon(Icons.delete, color: Colors.red),
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
}