import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';
import '../../service/stok_opname_service.dart';

class DetailStokOpnameScreen extends StatefulWidget {
  const DetailStokOpnameScreen({super.key});

  @override
  State<DetailStokOpnameScreen> createState() => _DetailStokOpnameScreenState();
}

class _DetailStokOpnameScreenState extends State<DetailStokOpnameScreen> {

  String? idStokOpname;

  Map<String, dynamic>? headerData;
  List<dynamic> detailItems = [];

  bool isLoading = true;
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    idStokOpname = ModalRoute.of(context)!.settings.arguments as String;

    loadData();
  }

  // =========================
  // LOAD DATA HEADER + DETAIL
  // =========================
  Future<void> loadData() async {
    try {
      final header = await StokOpnameService.getStokOpnameById(idStokOpname!);
      final detail = await StokOpnameService.getDetailStokOpname(idStokOpname!);

      setState(() {
        headerData = header;
        detailItems = detail;
        isLoading = false;
      });

    } catch (e) {
      print("ERROR LOAD DETAIL: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) return;
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
    detailItems.sort((a, b) {
      int result;
      switch (ci) {
        case 1:
          result = (a['kartu_stok']?['produk']?['nama_produk'] ?? '').toString().compareTo(
              (b['kartu_stok']?['produk']?['nama_produk'] ?? '').toString());
          break;
        case 2:
          result = ((a['detail']?['stok_sistem'] ?? 0) as num)
              .compareTo((b['detail']?['stok_sistem'] ?? 0) as num);
          break;
        case 3:
          result = ((a['detail']?['stok_fisik'] ?? 0) as num)
              .compareTo((b['detail']?['stok_fisik'] ?? 0) as num);
          break;
        case 4:
          result = ((a['detail']?['selisih'] ?? 0) as num)
              .compareTo((b['detail']?['selisih'] ?? 0) as num);
          break;
        case 5:
          result = (a['detail']?['keterangan_barang'] ?? '').toString().compareTo(
              (b['detail']?['keterangan_barang'] ?? '').toString());
          break;
        default:
          return 0;
      }
      return asc ? result : -result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlobalAppBar(title: 'Detail Stok Opname'),
                const SizedBox(height: 20),

                // =========================
                // TOMBOL KEMBALI
                // =========================
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

                const SizedBox(height: 20),

                // =========================
                // HEADER (DINAMIS)
                // =========================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderInfo(
                        'Tanggal Stok Opname',
                        headerData?['created_at']?.toString().substring(0, 10) ?? '-',
                      ),
                      _buildHeaderInfo(
                        'Petugas / PIC',
                        headerData?['user']?['nama_user'] ?? '-',
                      ),
                      _buildHeaderInfo(
                        'ID Stok Opname',
                        headerData?['id_stok_opname'] ?? '-',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // =========================
                // TABLE DETAIL (DINAMIS)
                // =========================
                Expanded(
                  child: GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(label: const Text('Nama Barang'), onSort: _onSort),
                      DataColumn(label: const Text('Stok Sistem'), onSort: _onSort),
                      DataColumn(label: const Text('Stok Fisik'), onSort: _onSort),
                      DataColumn(label: const Text('Selisih'), onSort: _onSort),
                      DataColumn(label: const Text('Keterangan'), onSort: _onSort),
                    ],
                    rows: List.generate(detailItems.length, (index) {
                      final item = detailItems[index];

                      final detail = item['detail'];
                      final kartu = item['kartu_stok'];
                      final produk = kartu['produk'];

                      final stokSistem = detail['stok_sistem'];
                      final stokFisik = detail['stok_fisik'];
                      final selisih = detail['selisih'];

                      Color selisihColor = Colors.grey;
                      if (selisih < 0) selisihColor = Colors.red;
                      if (selisih > 0) selisihColor = Colors.green;
                      if (selisih == 0) selisihColor = Colors.black87;

                      return DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(Text(produk['nama_produk'] ?? '-')),
                          DataCell(Text(
                            stokSistem.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            stokFisik.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: selisih == 0
                                    ? Colors.transparent
                                    : selisihColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                selisih > 0 ? '+$selisih' : selisih.toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selisihColor),
                              ),
                            ),
                          ),
                          DataCell(Text(detail['keterangan_barang'] ?? '-')),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }

  // =========================
  // HEADER HELPER (TIDAK DIUBAH)
  // =========================
  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}