import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';
import '../../service/produk_service.dart';

class EditPembelianScreen extends StatefulWidget {
  const EditPembelianScreen({super.key});

  @override
  State<EditPembelianScreen> createState() => _EditPembelianScreenState();
}

class _EditPembelianScreenState extends State<EditPembelianScreen> {
  String? _idPembelian;
  String _tanggalPembelian = '';

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

  // State untuk Supplier
  String? _selectedSupplierId;
  String _leadTime = '-';
  List<dynamic> _suppliers = [];

  // State untuk Produk
  List<dynamic> _products = [];

  // State untuk Daftar Barang Dinamis
  final List<Map<String, dynamic>> _listBarang = [];

  bool _isLoading = true;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal muat master data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================
  // GET DETAIL DARI API
  // =========================
  Future<void> _fetchDetail() async {
    try {
      final data = await PembelianService.getDetailPembelian(_idPembelian!);

      final pembelian = data['pembelian'] ?? data;
      final supplierId = pembelian['id_supplier']?.toString();
      _tanggalPembelian = PembelianService.formatDate(pembelian['tanggal_pembelian']);

      if (_suppliers.any((s) => s['id_supplier'].toString() == supplierId)) {
        _selectedSupplierId = supplierId;
        final match = _suppliers.firstWhere((s) => s['id_supplier'].toString() == supplierId);
        _leadTime = '${match['lead_time'] ?? '-'} Hari';
      }

      final details = data['details'] ?? [];

      for (var item in details) {
        String kodeProduk = item['kode_produk'] ?? '';
        String qty = item['quantity'].toString();
        String harga = item['harga_beli']?.toString() ?? '0';

        String rop = '-';
        String stok = '-';
        String barang = '-';
        try {
          final prodMatch = _products.firstWhere((p) => p['kode_produk'] == kodeProduk);
          rop = '${prodMatch['reorder_point'] ?? '-'}';
          stok = '${prodMatch['stok_produk'] ?? '-'}';
          barang = '${prodMatch['nama_produk'] ?? '-'}';
        } catch (e) {}

        _listBarang.add({
          'kode_produk': kodeProduk,
          'barang': barang,
          'qty_controller': TextEditingController(text: qty),
          'harga_controller': TextEditingController(text: harga),
          'rop': rop,
          'stok': stok,
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
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
        'rop': '-',
        'stok': '-',
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

  // =========================
  // UPDATE KE API
  // =========================
  Future<void> _updatePembelian() async {
    try {
      if (_selectedSupplierId == null) {
        throw Exception("Supplier harus dipilih");
      }

      int idSupplier = int.parse(_selectedSupplierId!);

      List<Map<String, dynamic>> details = [];

      for (var item in _listBarang) {
        if (item['kode_produk'] == null) continue;

        final qtyText = item['qty_controller']?.text ?? '';
        if (qtyText.isEmpty) continue;

        final hargaText = item['harga_controller']?.text ?? '';
        int qty = int.parse(qtyText);
        int harga = int.tryParse(hargaText) ?? 0;

        details.add({
          "kode_produk": item['kode_produk'],
          "quantity": qty,
          "harga_beli": harga,
        });
      }

      // STEP 1: Update header
      await PembelianService.editPembelian(
        idPembelian: _idPembelian!,
        idSupplier: idSupplier,
      );

      // STEP 2: Update details
      await PembelianService.editDetailPembelian(
        idPembelian: _idPembelian!,
        details: details,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Perubahan Disimpan!',
          message: 'Data pembelian berhasil diperbarui.',
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
    } catch (e) {
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
          const GlobalAppBar(title: 'Edit Pembelian'),
          const SizedBox(height: 20),
          
          // Tombol Kembali
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.pembelian),
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
              child: Column(
                children: [
                  // Container Header Informasi
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildReadOnlyField(label: 'ID Pembelian', value: _idPembelian?.toString() ?? '-')),
                            const SizedBox(width: 20),
                            Expanded(child: _buildReadOnlyField(label: 'Tanggal Pembelian', value: _tanggalPembelian)),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildSupplierDropdown()),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: _buildReadOnlyField(label: 'Lead Time', value: _leadTime)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Daftar Barang
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Daftar Barang Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
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
                        Row(
                          children: [
                            Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('ROP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Hrg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 58),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_listBarang.length, (index) {
                          return _buildEditItemRow(index);
                        }),
                        const SizedBox(height: 20),
                        // --- TOTAL HARGA ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Total Harga: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Rp ${_totalHarga.toString()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        const SizedBox(height: 20),
                        
                        // Tombol Aksi Simpan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.pembelian),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton(
                              onPressed: _updatePembelian, // ⬅️ TERHUBUNG KE API
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange, 
                                foregroundColor: Colors.white, 
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // --- HELPER WIDGETS ---
  Widget _buildSupplierDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSupplierId,
            hint: const Text('Pilih nama supplier...'),
            decoration: _inputStyle(),
            items: _suppliers.map((s) {
              final id = s['id_supplier'].toString();
              final nama = s['nama_supplier'] ?? '';
              return DropdownMenuItem<String>(
                value: id,
                child: Text(nama),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSupplierId = val;
                final match = _suppliers.firstWhere((s) => s['id_supplier'].toString() == val);
                _leadTime = '${match['lead_time'] ?? '-'} Hari';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditItemRow(int index) {
    var item = _listBarang[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildDropdownBarang(item, index)),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: item['rop']),
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
              controller: TextEditingController(text: item['stok']),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: TextField(
              controller: item['harga_controller'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: _inputStyle().copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), hintText: '0'),
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
            child: IconButton(onPressed: () => _hapusBarang(index), icon: const Icon(Icons.delete, color: Colors.red)),
          )
        ],
      ),
    );
  }

  Widget _buildDropdownBarang(Map<String, dynamic> item, int index) {
    return Autocomplete<String>(
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
          item['stok'] = '${match['stok_produk'] ?? '-'}';
          item['rop'] = '${match['reorder_point'] ?? '-'}';
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
        if(textEditingController.text.isEmpty && (item['barang']??'').isNotEmpty) {
          textEditingController.text = item['barang'];
        }
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
      fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
    );
  }
}