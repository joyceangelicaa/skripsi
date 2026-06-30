import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../service/penjualan_service.dart';
import '../../service/customer_service.dart';
import '../../service/produk_service.dart';

class InputTransaksiScreen extends StatefulWidget {
  const InputTransaksiScreen({super.key});

  @override
  State<InputTransaksiScreen> createState() => _InputTransaksiScreenState();
}

class _InputTransaksiScreenState extends State<InputTransaksiScreen> {
  DateTime _tanggalPenjualan = DateTime.now();
  String _previewNomerPenjualan = '';
  int _selectedCustomerId = 0;
  String _selectedCustomerName = '';

  List<dynamic> _customers = [];
  List<dynamic> _produkList = [];

  final TextEditingController _diskonController = TextEditingController();

  List<Map<String, dynamic>> _listBarang = [];

  final Set<int> _loadingHarga = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _tambahBarisBarang();
  }

  @override
  void dispose() {
    for (var item in _listBarang) {
      item['qty']?.dispose();
      item['harga_controller']?.dispose();
    }
    _diskonController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        CustomerService.getAllCustomer(limit: 999),
        ProdukService.getAllProduk(limit: 999),
      ]);
      setState(() {
        _customers = results[0] as List;
        _produkList = results[1] as List;
      });
    } catch (e) {
      print("ERROR LOAD DATA: $e");
    }
  }

  // Future<void> _generatePenjualan() async {
  //   if (_selectedCustomerId == 0) return;
  //   try {
  //     final nomer = await PenjualanService.addPenjualan(
  //       idCustomer: _selectedCustomerId,
  //       potonganHarga: double.tryParse(_diskonController.text) ?? 0,
  //     );
  //     if (mounted) {
  //       setState(() {
  //         _previewNomerPenjualan = nomer;
  //       });
  //     }
  //   } catch (e) {
  //     print("ERROR GENERATE PENJUALAN: $e");
  //   }
  // }

  Future<void> _batal() async {
    // if (_previewNomerPenjualan.isNotEmpty) {
    //   try {
    //     await PenjualanService.deletePenjualan(_previewNomerPenjualan);
    //   } catch (_) {}
    // }
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoute.transaksi);
    }
  }

  void _tambahBarisBarang() {
    setState(() {
      _listBarang.add({'qty': TextEditingController(), 'barang': '', 'kode_produk': '', 'harga': '0', 'total': '0',
      'harga_controller': TextEditingController(), 'harga_default': '0',});
    });
  }

  void _hapusBarisBarang(int index) {
    _listBarang[index]['harga_controller']?.dispose();
    setState(() {
      _listBarang.removeAt(index);
      _loadingHarga.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9), 
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- JUDUL HALAMAN ---
          const GlobalAppBar(title: 'Input Transaksi'),
          const SizedBox(height: 15),

          // --- TOMBOL KEMBALI ---
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _batal,
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

          // --- KERTAS FORM TRANSAKSI ---
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
                    // --- HEADER: Tanggal, Customer ---
                    Row(
                      children: [
                        Expanded(child: _buildDatePickerField(     // ← tambah Expanded
                          label: 'Tanggal Transaksi',
                          selectedDate: _tanggalPenjualan,
                          onChanged: (date) => setState(() => _tanggalPenjualan = date),
                        )),
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
                        onPressed: _tambahBarisBarang,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        label: const Text('Tambah Barang', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- HEADER TABEL NOTA ---
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

                    // --- BARIS INPUT BARANG ---
                    Column(
                      children: List.generate(_listBarang.length, (index) {
                        var item = _listBarang[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _buildItemRow(
                            index: index,
                            item: item,
                            // qty: item['qty']!, 
                            // barang: item['barang']!, 
                            // harga: item['harga']!, 
                            // total: item['total']!
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 20),

                    // --- FOOTER: Total, Diskon, Button Simpan ---
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
                                  _formatRupiah(_hitungSubtotal()),
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
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontSize: 14),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
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
                                  _formatRupiah(_hitungTotalAkhir()),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_selectedCustomerId == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Pilih customer terlebih dahulu')),
                                    );
                                    return;
                                  }
                                  if (_listBarang.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Tambah minimal 1 barang')),
                                    );
                                    return;
                                  }
                                  try {
                                    final nilaiDiskon = double.tryParse(_diskonController.text) ?? 0;

                                    // if (_previewNomerPenjualan.isEmpty) {
                                    //   throw Exception("Generate penjualan dulu dengan memilih customer");
                                    // }

                                    //generate header penjualan dulu
                                    final formattedTgl = '${_tanggalPenjualan.year}-${_tanggalPenjualan.month.toString().padLeft(2, '0')}-${_tanggalPenjualan.day.toString().padLeft(2, '0')}';
                                    final nomerPenjualan = await PenjualanService.addPenjualan(
                                      idCustomer: _selectedCustomerId,
                                      potonganHarga: nilaiDiskon,
                                      tanggalPenjualan: formattedTgl,
                                    );
                                    if (mounted) setState(() => _previewNomerPenjualan = nomerPenjualan);

                                    //simpan detail penjualan
                                    final details = _listBarang.map((item){
                                      return {
                                        'nomer_penjualan': nomerPenjualan,
                                        'kode_produk': item['kode_produk'] ?? '',
                                        'quantity': int.tryParse(item['qty'].text) ?? 1,
                                        'harga_jual': double.tryParse(item['harga'] ?? '0') ?? 0,
                                      };
                                    }).toList();

                                    //debug lihat isi yang di kirim ke backend
                                    debugPrint("DETAIL PENJUALAN: $details");
                                    final warnings = await PenjualanService.addDetailPenjualan(details);

                                    if (warnings.isNotEmpty && context.mounted) {
                                      final shouldContinue = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Peringatan Harga'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: warnings.map((w) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(w),
                                            )).toList(),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Batalkan'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Tetap Simpan'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldContinue != true) {
                                        await PenjualanService.deletePenjualan(nomerPenjualan);
                                        return;
                                      }
                                    }

                                    //update header penjualan dengan total harga akhir
                                    await PenjualanService.editPenjualan(nomerPenjualan: nomerPenjualan,
                                    idCustomer: _selectedCustomerId,
                                    potonganHarga: nilaiDiskon,
                                    );

                                    if (!context.mounted) return;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const ConfirmationDialog(
                                        isSuccess: true,
                                        title: 'Transaksi Berhasil!',
                                        message: 'Data transaksi penjualan telah berhasil disimpan.',
                                      ),
                                    );
                                    await Future.delayed(const Duration(seconds: 1));
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    Navigator.pushReplacementNamed(context, AppRoute.detailTransaksi,
                                      arguments: {
                                        'nomer_penjualan': _previewNomerPenjualan,
                                        'tanggal_penjualan': _tanggalPenjualan.toIso8601String(),
                                        'total_harga': _hitungTotalAkhir(),
                                        'potongan_harga': nilaiDiskon,
                                        'id_kustomer': _selectedCustomerId,
                                        'nama_customer': _selectedCustomerName,
                                      },
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal simpan: $e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Simpan Transaksi'),
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

  // --- WIDGET HELPER ---
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
              _refetchAllHarga();
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
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

  Widget _buildItemRow({required int index, required Map<String, dynamic> item}) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            controller: item['qty'],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: _inputStyle(),
            onChanged: (val) {
              _updateTotalRow(index);
            },
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
              final matched = _produkList.firstWhere((p) {
                final pkode = p is Map<String, dynamic> ? p['kode_produk'] : '';
                return pkode == kode;
              });
              final hargaJual = matched is Map<String, dynamic>
                  ? (matched['harga_jual'] ?? 0).toString()
                  : '0';
              setState(() {
                _listBarang[index]['barang'] = selection;
                _listBarang[index]['kode_produk'] = kode;
                _listBarang[index]['harga'] = hargaJual;
                _listBarang[index]['harga_default'] = hargaJual;
                (_listBarang[index]['harga_controller'] as TextEditingController).text = hargaJual;
              });
              _updateTotalRow(index);
              if (_selectedCustomerId != 0 && kode.isNotEmpty) {
                _fetchCustomerHarga(index, kode);
              }
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: _inputStyle().copyWith(hintText: 'Cari Barang...'),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: item['harga_controller'],
                keyboardType: TextInputType.number,
                decoration: _inputStyle().copyWith(prefixText: 'Rp '),
                onChanged: (val) {
                  _listBarang[index]['harga'] = val;
                  _updateTotalRow(index);
                },
              ),
              if (_loadingHarga.contains(index))
                const Positioned(
                  right: 8,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: TextField(
            controller: TextEditingController(text: _formatRupiah(double.tryParse(item['total'] ?? '0') ?? 0)),
            readOnly: true,
            decoration: _inputStyle(readOnly: true),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Hapus Item',
          onPressed: () {
            _hapusBarisBarang(index);
          },
          splashRadius: 20,
        ),
      ],
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

  Future<void> _fetchCustomerHarga(int index, String kodeProduk) async {
    if (index >= _listBarang.length) return;
    final defaultHarga = _listBarang[index]['harga_default'] as String? ?? '0';
    setState(() => _loadingHarga.add(index));
    (_listBarang[index]['harga_controller'] as TextEditingController).text = 'Memuat...';
    try {
      debugPrint('--- getCustomerHarga ---');
      debugPrint('URL: /customer/harga/$kodeProduk/$_selectedCustomerId/1');
      final harga = await CustomerService.getCustomerHarga(
        kodeProduk: kodeProduk,
        idCustomer: _selectedCustomerId,
      );
      if (!mounted || index >= _listBarang.length) return;
      if (harga != null) {
        final hargaStr = harga.toStringAsFixed(0);
        setState(() {
          _listBarang[index]['harga'] = hargaStr;
          _listBarang[index]['harga_default'] = hargaStr;
          (_listBarang[index]['harga_controller'] as TextEditingController).text = hargaStr;
          _loadingHarga.remove(index);
        });
        _updateTotalRow(index);
      } else {
        debugPrint('Response: null (no prior price)');
        _restoreDefaultHarga(index, defaultHarga);
      }
    } catch (e) {
      debugPrint('ERROR getCustomerHarga: $e');
      if (mounted) _restoreDefaultHarga(index, defaultHarga);
    }
  }

  Future<void> _refetchAllHarga() async {
    if (_selectedCustomerId == 0) return;
    final futures = <Future<void>>[];
    for (int i = 0; i < _listBarang.length; i++) {
      final kode = _listBarang[i]['kode_produk'] as String? ?? '';
      if (kode.isNotEmpty) {
        futures.add(_fetchCustomerHarga(i, kode));
      }
    }
    await Future.wait(futures);
  }

  void _restoreDefaultHarga(int index, String defaultHarga) {
    if (index >= _listBarang.length) return;
    setState(() {
      _listBarang[index]['harga'] = defaultHarga;
      (_listBarang[index]['harga_controller'] as TextEditingController).text = defaultHarga;
      _loadingHarga.remove(index);
    });
    _updateTotalRow(index);
  }

  void _updateTotalRow(int index) {
    final qty = int.tryParse(_listBarang[index]['qty'].text) ?? 1;
    final harga = double.tryParse(_listBarang[index]['harga'] ?? '0') ?? 0;
    final total = qty * harga;
    setState(() {
      _listBarang[index]['total'] = total.toStringAsFixed(0);
    });
  }

  double _hitungSubtotal() {
    double sum = 0;
    for (var item in _listBarang) {
      sum += double.tryParse(item['total'] ?? '0') ?? 0;
    }
    return sum;
  }

  double _hitungTotalAkhir() {
    final subtotal = _hitungSubtotal();
    final diskon = double.tryParse(_diskonController.text) ?? 0;
    return subtotal - diskon;
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
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
    );
  }
}