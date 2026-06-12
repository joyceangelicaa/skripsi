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
  String? _generatedIdPenerimaan;
  bool _isLoading = true;

  String tanggal = '';
  String idPembelian = '';
  String supplier = '';
  String totalHarga = '0';

  List<Map<String, dynamic>> items = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _products = [];

  final List<Map<String, dynamic>> _listBatch = [];

  @override
  void initState() {
    super.initState();
    _tambahBatch();
  }

  @override
  void dispose() {
    for (var batch in _listBatch) {
      batch['terima_controller'].dispose();
      batch['keterangan_controller'].dispose();
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
        String rop = '-';
        String stok = '-';
        try {
          final p = _products.firstWhere((p) => p['kode_produk'] == kode);
          namaBarang = p['nama_produk'] ?? kode;
          rop = '${p['reorder_point'] ?? '-'}';
          stok = '${p['stok_produk'] ?? '-'}';
        } catch (_) {}

        return {
          'kode_produk': kode,
          'nama_barang': namaBarang,
          'harga': item['harga_beli'] ?? 0,
          'qty': item['quantity'] ?? 0,
          'rop': rop,
          'stok': stok,
        };
      }).toList();

      setState(() {
        idPembelian = pembelian['id_pembelian'].toString();
        tanggal = PembelianService.formatDate(pembelian['tanggal_pembelian']);
        supplier = namaSupplier;
        totalHarga = pembelian['total_harga']?.toString() ?? '0';
        items = List<Map<String, dynamic>>.from(itemList);
        _isLoading = false;
      });

      await _generateIdPenerimaan();
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

  void _tambahBatch() {
    setState(() {
      _listBatch.add({
        'kode_produk': null,
        'barang': '',
        'qty_pesan': '-',
        'preview_batch_code': null,
        'terima_controller': TextEditingController(),
        'keterangan_controller': TextEditingController(),
      });
    });
  }

  void _hapusBatch(int index) {
    setState(() {
      _listBatch[index]['terima_controller'].dispose();
      _listBatch[index]['keterangan_controller'].dispose();
      _listBatch.removeAt(index);
    });
  }

  // =========================
  // GENERATE ID + BATAL
  // =========================
  Future<void> _generateIdPenerimaan() async {
    if (_generatedIdPenerimaan != null) return;
    try {
      final id = await PenerimaanService.addPenerimaan(
        idPembelian: _idPembelianArgs!,
        totalHarga: 0,
      );
      if (mounted) setState(() => _generatedIdPenerimaan = id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate ID: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _batal() async {
    if (_generatedIdPenerimaan != null) {
      await PenerimaanService.deletePenerimaan(_generatedIdPenerimaan!);
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
    }
  }

  double _getHargaSatuan(String kodeProduk) {
    try {
      final match = items.firstWhere((i) => i['kode_produk'] == kodeProduk);
      return (match['harga'] as num).toDouble();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadPreviewBatchCode(Map<String, dynamic> item) async {
    try {
      final kode = await PenerimaanService.getNextBatchCode();
      if (mounted) {
        setState(() => item['preview_batch_code'] = kode);
      }
    } catch (_) {}
  }

  // ================== 🔥 FUNCTION SUBMIT ==================
  Future<void> _submitPenerimaan() async {
    try {
      if (_idPembelianArgs == null) {
        throw Exception("ID Pembelian tidak ditemukan");
      }

      if (_generatedIdPenerimaan == null) {
        throw Exception("ID Penerimaan belum digenerate");
      }

      List<Map<String, dynamic>> details = [];

      for (var batch in _listBatch) {
        if (batch['kode_produk'] == null) continue;

        details.add({
          "kode_produk": batch['kode_produk'],
          "quantity_dipesan": int.tryParse(batch['qty_pesan'].toString()) ?? 0,
          "quantity_diterima": int.tryParse(batch['terima_controller'].text) ?? 0,
          "keterangan_barang": batch['keterangan_controller'].text
        });
      }

      final detailPayload = details.map((d) => {
        'id_penerimaan': _generatedIdPenerimaan,
        'kode_produk': d['kode_produk'],
        'quantity_dipesan': d['quantity_dipesan'],
        'quantity_diterima': d['quantity_diterima'],
        'keterangan_barang': d['keterangan_barang'],
      }).toList();

      final addResult = await PenerimaanService.addDetailPenerimaan(detailPayload);

      // for (var d in details) {
      //   await KartuStokService.addKartuStok(
      //     kodeProduk: d['kode_produk'],
      //     stokMasuk: d['quantity_diterima'],
      //     keteranganBarang: "Penerimaan",
      //   );
      // }

      final detailResults = addResult['detail_penerimaan'] as List<dynamic>? ?? [];

      final editDetails = detailResults.asMap().entries.map((entry) {
        final detail = details[entry.key];
        return {
          'id_detail_penerimaan': entry.value['id_detail_penerimaan'],
          'kode_produk': detail['kode_produk'],
          'quantity_dipesan': detail['quantity_dipesan'],
          'quantity_diterima': detail['quantity_diterima'],
          'keterangan_barang': detail['keterangan_barang'],
        };
      }).toList();

      // Hitung total dari quantity_diterima × harga
      int totalTerima = 0;
      for (var detail in details) {
        final terima = detail['quantity_diterima'] as int;
        final harga = _getHargaSatuan(detail['kode_produk'] as String);
        totalTerima += (terima * harga).toInt();
      }

      // Update header dengan total yang benar
      await PenerimaanService.editPenerimaan(
        idPenerimaan: _generatedIdPenerimaan!,
        idPembelian: _idPembelianArgs!,
        totalHarga: totalTerima,
        details: editDetails,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Barang Berhasil Diterima!',
          message: 'Data penerimaan batch telah dicatat dan stok gudang otomatis bertambah.',
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

  // ================== UI (TIDAK DIUBAH) ==================
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
                  // ====== (SEMUA UI DI BAWAH INI SAMA PERSIS PUNYAMU) ======

                  // --- SECTION 1 ---
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
                          children: [
                            Expanded(child: _buildReadOnlyField(label: 'ID Penerimaan', value: _generatedIdPenerimaan ?? '-')),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- SECTION 2: DATA PEMBELIAN (READ-ONLY) ---
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
                          'Data Pembelian',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
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
                            Expanded(flex: 1, child: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
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
                                    controller: TextEditingController(text: item['rop'].toString()),
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
                                    controller: TextEditingController(text: item['stok'].toString()),
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: _inputStyle(readOnly: true).copyWith(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      fillColor: Colors.blue.shade50,
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: TextEditingController(text: item['harga'].toString()),
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
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Total Harga: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Rp $totalHarga',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- SECTION 3: BATCH CRUD ---
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Penerimaan Barang',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                            ),
                            ElevatedButton.icon(
                              onPressed: _tambahBatch,
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Input Batch', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            Expanded(flex: 3, child: Text('Nomor Batch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Qty Pesan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 1, child: Text('Qty Terima', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 15),
                            Expanded(flex: 4, child: Text('Keterangan Barang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                            const SizedBox(width: 58),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_listBatch.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text('Belum ada batch yang diinput. Klik "Input Batch" untuk menambahkan.',
                                style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          ...List.generate(_listBatch.length, (index) {
                            return _buildBatchRow(index);
                          }),
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
                              onPressed: _submitPenerimaan,
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

  Widget _buildBatchRow(int index) {
    var item = _listBatch[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          // KOLOM 1: Nama Barang
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return items.map((p) => p['nama_barang']?.toString() ?? '')
                      .where((n) => n.isNotEmpty);
                }
                final query = textEditingValue.text.toLowerCase();
                return items.map((p) => p['nama_barang']?.toString() ?? '')
                    .where((n) => n.isNotEmpty && n.toLowerCase().contains(query));
              },
              onSelected: (selection) {
                final match = items.firstWhere((p) => p['nama_barang'] == selection);
                setState(() {
                  item['kode_produk'] = match['kode_produk'];
                  item['barang'] = selection;
                  item['qty_pesan'] = match['qty'].toString();
                });
                _loadPreviewBatchCode(item);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
                if (textEditingController.text.isEmpty && (item['barang'] ?? '').isNotEmpty) {
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
            ),
          ),
          const SizedBox(width: 15),
          // KOLOM 2: Nomor Batch (read-only — preview dari API)
          Expanded(
            flex: 3,
            child: TextField(
              controller: TextEditingController(text: item['preview_batch_code'] ?? 'Pilih Barang...'),
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: _inputStyle(readOnly: true).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                fillColor: Colors.grey.shade200,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
            ),
          ),
          const SizedBox(width: 15),
          // KOLOM 3: Quantity Dipesan (read-only)
          Expanded(
            flex: 1,
            child: TextField(
              controller: TextEditingController(text: item['qty_pesan']),
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
          // KOLOM 4: Quantity Dibeli (input — terima_controller)
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
          // KOLOM 5: Keterangan Barang (input — keterangan_controller)
          Expanded(
            flex: 4,
            child: TextField(
              controller: item['keterangan_controller'],
              decoration: _inputStyle().copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                hintText: 'Catatan...',
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _hapusBatch(index),
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