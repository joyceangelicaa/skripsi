import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';
import '../../service/penjualan_service.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/delete_confirmation_dialog.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  List<Map<String, dynamic>> allPenjualan = [];
  List<Map<String, dynamic>> _filteredPenjualan = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await PenjualanService.getAllPenjualan(limit: 9999, offset: 0);
      data.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      allPenjualan = data.where((item) => (item['total_harga'] ?? 0) > 0).toList();
      _filteredPenjualan = List.from(allPenjualan);
      setState(() => isLoading = false);
    } catch (e) {
      print("ERROR TRANSAKSI: $e");
      setState(() => isLoading = false);
    }
  }

  String formatDate(String? date) {
    if (date == null) return "-";
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return date;
    }
  }

  String formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    final str = number.toStringAsFixed(0).split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Future<void> _deletePenjualan(String nomerPenjualan, String namaCustomer) async {
    showDialog(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        title: 'Hapus Transaksi',
        message: 'Hapus transaksi $nomerPenjualan ($namaCustomer)?',
        onConfirmDelete: () async {
          try {
            await PenjualanService.deletePenjualan(nomerPenjualan);
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (_) => const ConfirmationDialog(
                isSuccess: true,
                title: 'Berhasil',
                message: 'Transaksi berhasil dihapus.',
              ),
            );
            loadData();
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal hapus: $e')),
            );
          }
        },
      ),
    );
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPenjualan = List.from(allPenjualan);
      } else {
        _filteredPenjualan = allPenjualan.where((item) {
          return item.values.any((value) {
            return value.toString().toLowerCase().contains(query.toLowerCase());
          });
        }).toList();
      }
    });
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
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Transaksi'),
          const SizedBox(height: 20),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.inputTransaksi),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Input Transaksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterList,
                  decoration: InputDecoration(
                    hintText: 'Cari nomer transaksi atau nama customer...',
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
            ],
          ),

          const SizedBox(height: 30),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Nomer Transaksi')),
                      DataColumn(label: Text('Tgl Transaksi')),
                      DataColumn(label: Text('Nama Customer')),
                      DataColumn(label: Text('Total Harga')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(_filteredPenjualan.length, (index) {
                      final item = _filteredPenjualan[index];
                      return DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(
                            Text(
                              item['nomer_penjualan'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(formatDate(item['tanggal_penjualan']))),
                          DataCell(Text(item['customer']?['nama_customer'] ?? '-')),
                          DataCell(Text(formatRupiah(item['total_harga']))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
                                  tooltip: 'Lihat Detail',
                                  onPressed: () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoute.detailTransaksi,
                                    arguments: item,
                                  ),
                                  splashRadius: 20,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                  tooltip: 'Edit',
                                  onPressed: () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoute.editTransaksi,
                                    arguments: item,
                                  ),
                                  splashRadius: 20,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Hapus',
                                  onPressed: () => _deletePenjualan(
                                    item['nomer_penjualan'] ?? '',
                                    item['customer']?['nama_customer'] ?? '-',
                                  ),
                                  splashRadius: 20,
                                ),
                              ],
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
}
