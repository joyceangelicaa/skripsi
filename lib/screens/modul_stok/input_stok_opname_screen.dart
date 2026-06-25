import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';
import '../../service/stok_opname_service.dart'; 
import '../../service/produk_service.dart';
import '../../service/user_service.dart';

class InputStokOpnameScreen extends StatefulWidget {
  const InputStokOpnameScreen({super.key});

  @override
  State<InputStokOpnameScreen> createState() => _InputStokOpnameScreenState();
}

class _InputStokOpnameScreenState extends State<InputStokOpnameScreen> {

  List<dynamic> items = [];
  List<dynamic> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  final List<TextEditingController> stokFisikControllers = [];
  final List<TextEditingController> keteranganControllers = [];

  String? idStokOpname;
  String? createdAt;
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is String) {
      idStokOpname = args;
    } else if (args is Map) {
      idStokOpname = args["id_stok_opname"];
      createdAt = args["created_at"];
    }

    if (createdAt == null) {
      createdAt = DateTime.now().toIso8601String();
    }

    loadProduk();
  }

  // LOAD PRODUK DARI API
  Future<void> loadProduk() async {
    try {
      final data = await ProdukService.getAllProduk(limit: 999, offset: 0);

      setState(() {
        items = data;
        _filteredItems = List.from(data);

        stokFisikControllers.clear();
        keteranganControllers.clear();

        for (var i = 0; i < items.length; i++) {
          stokFisikControllers.add(TextEditingController());
          keteranganControllers.add(TextEditingController());
        }
      });
    } catch (e) {
      print("ERROR LOAD PRODUK: $e");
    }
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(items);
      } else {
        _filteredItems = items.where((item) {
          return item.values.any((value) {
            return value.toString().toLowerCase().contains(query.toLowerCase());
          });
        }).toList();
      }
      _sortData();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0 || columnIndex == 3 || columnIndex == 4) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortData();
    });
  }

  void _sortData() {
    if (_sortColumnIndex == null) return;
    final ci = _sortColumnIndex!;
    final asc = _sortAscending;
    _filteredItems.sort((a, b) {
      int result;
      switch (ci) {
        case 1:
          result = (a['nama_produk'] ?? '').toString().compareTo(
              (b['nama_produk'] ?? '').toString());
          break;
        case 2:
          result = ((a['stok_produk'] ?? 0) as num)
              .compareTo((b['stok_produk'] ?? 0) as num);
          break;
        default:
          return 0;
      }
      return asc ? result : -result;
    });
  }

  // SIMPAN DATA KE BACKEND
  Future<void> simpanData() async {
    try {
      List<Map<String, dynamic>> payload = [];

      for (int i = 0; i < items.length; i++) {
        final stokFisikStr = stokFisikControllers[i].text.trim();
        final keterangan = keteranganControllers[i].text.trim();

        if (stokFisikStr.isEmpty && keterangan.isEmpty) continue;

        payload.add({
          "kode_produk": items[i]["kode_produk"],
          "stok_fisik": int.tryParse(stokFisikStr) ?? 0,
          "keterangan_barang": keterangan,
        });
      }

      if (payload.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => const ConfirmationDialog(
            isSuccess: false,
            title: 'Tidak Ada Data',
            message: 'Tidak ada data yang diisi. Silakan isi stok fisik atau keterangan.',
          ),
        );
        return;
      }

      if (idStokOpname == null) {
        final idUser = UserService.idUser;
        if (idUser == null) {
          throw Exception("User tidak ditemukan. Silakan login ulang.");
        }
        final res = await StokOpnameService.addStokOpname(idUser);
        idStokOpname = res['id_stok_opname'];
      }

      for (var item in payload) {
        item['id_stock_opname'] = idStokOpname;
      }

      await StokOpnameService.addDetailOpname(payload);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Berhasil Disimpan!',
          message: 'Data stok opname telah berhasil diperbarui dan dicatat.',
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, AppRoute.stokOpname);
      });

    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ConfirmationDialog(
          isSuccess: false,
          title: 'Gagal',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var c in stokFisikControllers) {
      c.dispose();
    }
    for (var c in keteranganControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Input Stok Opname'),
          const SizedBox(height: 15),

          // TOMBOL KEMBALI
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoute.stokOpname);
              },
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

          // HEADER 
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderInfo('Tanggal Stok Opname', _formatTanggal(createdAt)),
                    _buildHeaderInfo('Petugas', UserService.namaUser ?? '-'),
                    _buildHeaderInfo('ID Stok Opname', idStokOpname ?? 'ID akan terbuat otomatis'),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterList,
                        decoration: const InputDecoration(
                          hintText: 'Cari nama barang...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    ElevatedButton.icon(
                      onPressed: simpanData,
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: const Text('Simpan Stok Opname'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // TABLE 
          Expanded(
            child: items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(label: const Text('Nama Barang'), onSort: _onSort),
                      DataColumn(label: const Text('Stok Asli'), onSort: _onSort),
                      const DataColumn(label: Text('Hasil Opname')),
                      const DataColumn(label: Text('Keterangan')),
                    ],
                    rows: List.generate(_filteredItems.length, (index) {
                      final item = _filteredItems[index];

                      return DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(Text(item["nama_produk"] ?? '-')),
                          DataCell(Text(
                            item["stok_produk"].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),

                          DataCell(
                            SizedBox(
                              width: 120,
                              child: TextField(
                                // final originalIndex = items.indexOf(item);
                                controller: stokFisikControllers[items.indexOf(item)],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: '0',
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 250,
                              child: TextField(
                                controller: keteranganControllers[items.indexOf(item)],
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: Barang rusak / hilang',
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  // FORMAT TANGGAL
  String _formatTanggal(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  // HEADER HELPER
  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B))),
      ],
    );
  }
}