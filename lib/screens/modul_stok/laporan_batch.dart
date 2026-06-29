import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/table.dart';
import '../../service/produk_service.dart';

class LaporanBatchScreen extends StatefulWidget {
  const LaporanBatchScreen({super.key});

  @override
  State<LaporanBatchScreen> createState() => _LaporanBatchScreenState();
}

class _LaporanBatchScreenState extends State<LaporanBatchScreen> {
  bool isLoading = false;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final data = await ProdukService.getBatchAllProduk(limit: 999);
      setState(() {
        items = data;
        _filteredItems = List.from(data);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => isLoading = false);
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(items);
      } else {
        _filteredItems = items.where((item) {
          final produk = item['produk'] as Map<String, dynamic>? ?? {};
          return (produk['nama_produk']?.toString() ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (item['kode_batch']?.toString() ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      }
      _sortData();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
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
      final produkA = a['produk'] as Map<String, dynamic>? ?? {};
      final produkB = b['produk'] as Map<String, dynamic>? ?? {};
      int result;
      switch (ci) {
        case 1:
          result = (produkA['nama_produk'] ?? '').toString()
              .compareTo((produkB['nama_produk'] ?? '').toString());
          break;
        case 2:
          result = (a['kode_batch'] ?? '').toString()
              .compareTo((b['kode_batch'] ?? '').toString());
          break;
        case 3:
          result = (a['tanggal_masuk']?.toString() ?? '')
              .compareTo(b['tanggal_masuk']?.toString() ?? '');
          break;
        case 4:
          result = (num.tryParse(a['umur_barang']?.toString() ?? '0') ?? 0)
              .compareTo(num.tryParse(b['umur_barang']?.toString() ?? '0') ?? 0);
          break;
        case 5:
          result = (num.tryParse(a['total_stok']?.toString() ?? '0') ?? 0)
              .compareTo(num.tryParse(b['total_stok']?.toString() ?? '0') ?? 0);
          break;
        case 6:
          result = (num.tryParse(a['sisa_stok']?.toString() ?? '0') ?? 0)
              .compareTo(num.tryParse(b['sisa_stok']?.toString() ?? '0') ?? 0);
          break;
        default:
          return 0;
      }
      return asc ? result : -result;
    });
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String _formatWaktu(int? days) {
    if (days == null || days == 0) return 'Hari ini';
    return '$days Hari';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Laporan Batch'),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: TextField(
              controller: _searchController,
              onChanged: _filterList,
              decoration: InputDecoration(
                hintText: 'Cari nama barang atau batch...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(label: const Text('Nama Barang'), onSort: _onSort),
                      DataColumn(label: const Text('Batch'), onSort: _onSort),
                      DataColumn(label: const Text('Tgl Batch'), onSort: _onSort),
                      DataColumn(label: const Text('Sudah Berapa Lama'), onSort: _onSort),
                      DataColumn(label: const Text('Total Stok'), onSort: _onSort),
                      DataColumn(label: const Text('Sisa Stok'), onSort: _onSort),
                    ],
                    rows: List.generate(_filteredItems.length, (index) {
                      final item = _filteredItems[index];
                      final produk = item['produk'] as Map<String, dynamic>? ?? {};
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(produk['nama_produk']?.toString() ?? '-')),
                        DataCell(Text(item['kode_batch']?.toString() ?? '-')),
                        DataCell(Text(_formatTanggal(item['tanggal_masuk']?.toString()))),
                        DataCell(Text(_formatWaktu(int.tryParse(item['umur_barang']?.toString() ?? '')))),
                        DataCell(Text('${item['total_stok'] ?? 0}')),
                        DataCell(Text(
                          '${item['sisa_stok'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                      ]);
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}