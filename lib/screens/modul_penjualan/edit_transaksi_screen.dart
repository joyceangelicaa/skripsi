import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../service/penjualan_service.dart';
import '../../service/customer_service.dart';
import '../../service/produk_service.dart';

class EditTransaksiScreen extends StatefulWidget {
  const EditTransaksiScreen({super.key});

  @override
  State<EditTransaksiScreen> createState() => _EditTransaksiScreenState();
}

class _EditTransaksiScreenState extends State<EditTransaksiScreen> {
  // --- DATA HEADER ---
  String _nomerPenjualan = '';
  String _tanggalPenjualan = '';
  int _selectedCustomerId = 0;
  String _selectedCustomerName = '';
  final TextEditingController _diskonController = TextEditingController();

  // --- MASTER DATA ---
  List<dynamic> _customers = [];
  List<dynamic> _produkList = [];

  // --- DETAIL BARANG ---
  final List<Map<String, dynamic>> _listBarang = [];

  final Set<int> _loadingHarga = {};

  bool _isLoading = true;

  double get _totalAkhir {
    double total = 0;
    for (var item in _listBarang) {
      final qty = int.tryParse(item['qty']?.text ?? '0') ?? 0;
      final harga = double.tryParse(item['harga']?.text ?? '0') ?? 0;
      total += qty * harga;
    }
    final diskon = double.tryParse(_diskonController.text) ?? 0;
    return total - diskon;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nomerPenjualan.isEmpty) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _nomerPenjualan = args['nomer_penjualan'] ?? '';
        _tanggalPenjualan = _formatDate(args['tanggal_penjualan']);
        _diskonController.text = (args['potongan_harga'] ?? 0).toString();
        _selectedCustomerId = int.tryParse(args['id_kustomer']?.toString() ?? '') ?? int.tryParse(args['id_customer']?.toString() ?? '') ?? 0;
      }
      _loadData();
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

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        CustomerService.getAllCustomer(limit: 999),
        ProdukService.getAllProduk(limit: 999),
        PenjualanService.getDetailPenjualan(_nomerPenjualan),
      ]);
      _customers = results[0] as List;
      _produkList = results[1] as List;

      final matchedCustomer = _customers.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['id_customer'] == _selectedCustomerId,
        orElse: () => <String, dynamic>{},
      );
      _selectedCustomerName = matchedCustomer['nama_customer'] ?? '';

      final details = results[2] as List<Map<String, dynamic>>;
      for (var d in details) {
        final kode = d['kode_produk'] ?? '';
        final nama = _cariNamaProduk(kode);
        _listBarang.add({
          'id_detail': d['id_detail_penjualan'],
          'kode_produk': kode,
          'nama_produk': nama,
          'qty': TextEditingController(text: (d['quantity'] ?? 0).toString()),
          'harga': TextEditingController(text: (d['harga_jual'] ?? 0).toString()),
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("ERROR LOAD EDIT: $e");
      setState(() => _isLoading = false);
    }
  }

  String _cariNamaProduk(String kode) {
    try {
      final p = _produkList.firstWhere((p) => p['kode_produk'] == kode);
      if (p is Map<String, dynamic>) {
        final nama = p['nama_produk'] ?? '';
        return '$nama ($kode)';
      }
      return kode;
    } catch (_) {
      return kode;
    }
  }

  String _cariKodeProduk(String input) {
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(input);
    if (match != null) return match.group(1) ?? '';
    try {
      final p = _produkList.firstWhere(
        (p) => (p is Map<String, dynamic> ? p['nama_produk'] : '') == input,
      );
      return p is Map<String, dynamic> ? p['kode_produk'] ?? '' : '';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    for (var item in _listBarang) {
      item['qty']?.dispose();
      item['harga']?.dispose();
    }
    _diskonController.dispose();
    super.dispose();
  }

  void _tambahBaris() {
    setState(() {
      _listBarang.add({
        'id_detail': null,
        'kode_produk': '',
        'nama_produk': '',
        'qty': TextEditingController(text: ''),
        'harga': TextEditingController(text: '0'),
      });
    });
  }

  void _hapusBaris(int index) {
    setState(() {
      _listBarang[index]['qty']?.dispose();
      _listBarang[index]['harga']?.dispose();
      _listBarang.removeAt(index);
      _loadingHarga.remove(index);
    });
  }

  Future<void> _fetchCustomerHarga(int index, String kodeProduk) async {
    setState(() => _loadingHarga.add(index));
    _listBarang[index]['harga']?.text = 'Memuat...';
    try {
      final harga = await CustomerService.getCustomerHarga(
        kodeProduk: kodeProduk,
        idCustomer: _selectedCustomerId,
      );
      if (!mounted || index >= _listBarang.length) return;
      if (harga != null) {
        setState(() {
          _listBarang[index]['harga']?.text = harga.toStringAsFixed(0);
          _loadingHarga.remove(index);
        });
      } else {
        setState(() => _loadingHarga.remove(index));
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHarga.remove(index));
    }
  }

  double _hitungSubtotal() {
    double sum = 0;
    for (var item in _listBarang) {
      final qty = int.tryParse(item['qty']?.text ?? '0') ?? 0;
      final harga = double.tryParse(item['harga']?.text ?? '0') ?? 0;
      sum += qty * harga;
    }
    return sum;
  }

  // =========================
  // SIMPAN PERUBAHAN
  // =========================
  Future<void> _simpan() async {
    if (_selectedCustomerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih customer terlebih dahulu')),
      );
      return;
    }

    try {
      final diskon = double.tryParse(_diskonController.text) ?? 0;

      // 1. Update header
      await PenjualanService.editPenjualan(
        nomerPenjualan: _nomerPenjualan,
        idCustomer: _selectedCustomerId,
        potonganHarga: diskon,
      );

      // 2. Update detail
      final details = _listBarang
          .where((item) => (item['kode_produk'] ?? '').isNotEmpty)
          .map((item) {
        return {
          "kode_produk": item['kode_produk'],
          "quantity": int.tryParse(item['qty']?.text ?? '0') ?? 0,
          "harga_jual": double.tryParse(item['harga']?.text ?? '0') ?? 0,
        };
      }).toList();

      await PenjualanService.editDetailPenjualan(
        nomerPenjualan: _nomerPenjualan,
        details: details,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Perubahan Disimpan!',
          message: 'Data transaksi penjualan berhasil diperbarui.',
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoute.transaksi);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
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
          const GlobalAppBar(title: 'Edit Transaksi'),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.transaksi),
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
                padding: const EdgeInsets.all(24),
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
                    // --- HEADER: No Transaksi, Tanggal, Customer ---
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField(label: 'Nomor Transaksi', value: _nomerPenjualan)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildReadOnlyField(label: 'Tanggal Transaksi', value: _tanggalPenjualan)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildCustomerDropdown()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 10),

                    // --- TOMBOL TAMBAH BARANG ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _tambahBaris,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        label: const Text('Tambah Barang', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- HEADER TABEL ---
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

                    // --- BARIS ITEM ---
                    Column(
                      children: List.generate(_listBarang.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _buildItemRow(index),
                        );
                      }),
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 20),

                    // --- FOOTER: Total, Diskon, Total Akhir ---
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
                                Text(
                                  'Rp ${_hitungSubtotal().toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                ),
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
                                    controller: _diskonController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF1E293B)),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Akhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(
                                  'Rp ${_totalAkhir.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            // --- TOMBOL SIMPAN ---
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _simpan,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Simpan Perubahan'),
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

  // =========================
  // HELPER WIDGETS
  // =========================

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

  Widget _buildCustomerDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _customers.map((c) {
                  return c is Map<String, dynamic> ? c['nama_customer']?.toString() ?? '' : '';
                }).where((n) => n.isNotEmpty);
              }
              final query = textEditingValue.text.toLowerCase();
              return _customers.map((c) {
                return c is Map<String, dynamic> ? c['nama_customer']?.toString() ?? '' : '';
              }).where((n) => n.isNotEmpty && n.toLowerCase().contains(query));
            },
            onSelected: (selection) {
              final matched = _customers.firstWhere((c) {
                final nama = c is Map<String, dynamic> ? c['nama_customer'] : '';
                return nama == selection;
              });
              setState(() {
                _selectedCustomerName = selection;
                _selectedCustomerId = matched is Map<String, dynamic>
                    ? matched['id_customer'] ?? 0
                    : 0;
              });
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
              if (_selectedCustomerName.isNotEmpty && textEditingController.text.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (textEditingController.text.isEmpty) {
                    textEditingController.text = _selectedCustomerName;
                  }
                });
              }
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Pilih nama customer...',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _listBarang[index];
    final qty = int.tryParse(item['qty']?.text ?? '0') ?? 0;
    final harga = double.tryParse(item['harga']?.text ?? '0') ?? 0;
    final total = qty * harga;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              controller: item['qty'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: _inputStyle(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final list = _produkList.map((p) {
                  if (p is Map<String, dynamic>) {
                    final nama = p['nama_produk']?.toString() ?? '';
                    final kode = p['kode_produk']?.toString() ?? '';
                    return '$nama ($kode)';
                  }
                  return '';
                }).where((n) => n.isNotEmpty);
                if (textEditingValue.text.isEmpty) return list;
                final query = textEditingValue.text.toLowerCase();
                return list.where((n) => n.toLowerCase().contains(query));
              },
              onSelected: (selection) {
                final match = RegExp(r'\(([^)]+)\)$').firstMatch(selection);
                final kode = match?.group(1) ?? '';
                final matched = _produkList.firstWhere(
                  (p) => (p is Map<String, dynamic> ? p['kode_produk'] : '') == kode,
                );
                final hargaJual = matched is Map<String, dynamic>
                    ? (matched['harga_jual'] ?? 0).toString()
                    : '0';
                setState(() {
                  item['kode_produk'] = kode;
                  item['nama_produk'] = selection;
                  item['harga']?.text = hargaJual;
                });
                if (_selectedCustomerId != 0 && kode.isNotEmpty) {
                  _fetchCustomerHarga(index, kode);
                }
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                if (controller.text.isEmpty && item['nama_produk']?.isNotEmpty == true) {
                  controller.text = item['nama_produk']!;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputStyle().copyWith(hintText: 'Cari Barang...'),
                  onChanged: (val) {
                    item['nama_produk'] = val;
                    item['kode_produk'] = _cariKodeProduk(val);
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: TextField(
              controller: item['harga'],
              keyboardType: TextInputType.number,
              decoration: _inputStyle(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: TextField(
              controller: TextEditingController(text: total.toStringAsFixed(0)),
              readOnly: true,
              textAlign: TextAlign.right,
              decoration: _inputStyle(readOnly: true).copyWith(prefixText: 'Rp ', prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _hapusBaris(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
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
}
