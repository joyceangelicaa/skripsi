import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';
import '../../service/penjualan_service.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../service/laporan_penjualan_pdf_service.dart';

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
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      String? startStr;
      String? endStr;
      if (_startDate != null) {
        startStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      }
      if (_endDate != null) {
        endStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      }

      final data = await PenjualanService.getAllPenjualan(
        limit: 9999,
        offset: 0,
        startDate: startStr,
        endDate: endStr,
      );
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
      _sortData();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0 || columnIndex == 5) return;
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
    _filteredPenjualan.sort((a, b) {
      int result;
      switch (ci) {
        case 1:
          result = (a['nomer_penjualan'] ?? '').toString().compareTo(
              (b['nomer_penjualan'] ?? '').toString());
          break;
        case 2:
          result = (a['tanggal_penjualan'] ?? '').toString().compareTo(
              (b['tanggal_penjualan'] ?? '').toString());
          break;
        case 3:
          result = (a['customer']?['nama_customer'] ?? '').toString().compareTo(
              (b['customer']?['nama_customer'] ?? '').toString());
          break;
        case 4:
          result = ((a['total_harga'] ?? 0) as num)
              .compareTo((b['total_harga'] ?? 0) as num);
          break;
        default:
          return 0;
      }
      return asc ? result : -result;
    });
  }
  Future<void> _cetakPdf() async {
    try {
      if (_filteredPenjualan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk dicetak')),
        );
        return;
      }

      final pdfBytes = await LaporanPenjualanPdfService.generateLaporanPenjualanPdf(
        items: _filteredPenjualan,
        startDate: _startDate,
        endDate: _endDate,
      );

      final filename = _startDate != null && _endDate != null
          ? 'data_penjualan_${LaporanPenjualanPdfService.formatDate(_startDate)}_${LaporanPenjualanPdfService.formatDate(_endDate)}.pdf'
          : 'data_penjualan.pdf';

      LaporanPenjualanPdfService.downloadPdf(pdfBytes, filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cetak PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        } else {
          _endDate = picked;
          _endDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
      loadData();
    }
  }

  Widget _buildDateField({required TextEditingController controller, required String hint, required bool isStart}) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.calendar_today, size: 16),
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
      onTap: () => _pickDate(isStart: isStart),
    );
  }

  Widget _buildSearchField() {
    return TextField(
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
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
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: _buildDateField(controller: _startDateController, hint: 'Tgl Mulai', isStart: true),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: _buildDateField(controller: _endDateController, hint: 'Tgl Akhir', isStart: false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _cetakPdf,
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text('Cetak PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      const SizedBox(width: 12),
                      Flexible(child: _buildDateField(controller: _startDateController, hint: 'Tgl Mulai', isStart: true)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildDateField(controller: _endDateController, hint: 'Tgl Akhir', isStart: false)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _cetakPdf,
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Cetak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(
                        label: const Text('Nomer Transaksi'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Tgl Transaksi'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Nama Customer'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Total Harga'),
                        onSort: _onSort,
                      ),
                      const DataColumn(label: Text('Action')),
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
