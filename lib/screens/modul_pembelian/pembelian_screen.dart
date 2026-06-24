import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/table.dart';
import '../../root/app_route.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';
import '../../service/laporan_pembelian_pdf_service.dart';

class PembelianScreen extends StatefulWidget {
  const PembelianScreen({super.key});

  @override
  State<PembelianScreen> createState() => _PembelianScreenState();
}

class _PembelianScreenState extends State<PembelianScreen> {

  List<Map<String, dynamic>> _listPO = [];
  List<Map<String, dynamic>> _filteredList = [];
  Map<String, String> _supplierMap = {};
  bool _isLoading = true;
  String? _deletingId;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchPembelian();
  }

  // =========================
  // GET DATA
  // =========================
  Future<void> _fetchPembelian() async {
    try {
      String? startStr;
      String? endStr;
      if (_startDate != null) {
        startStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      }
      if (_endDate != null) {
        endStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      }

      final results = await Future.wait([
        PembelianService.getAllPembelian(limit: 999, status: _selectedStatus ?? '', startDate: startStr, endDate: endStr),
        SupplierService.getAllSuppliers(limit: 999),
      ]);

      final data = results[0] as List<Map<String, dynamic>>;
      data.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      final suppliers = results[1] as List<dynamic>;

      final supplierMap = <String, String>{};
      for (var s in suppliers) {
        supplierMap[s['id_supplier'].toString()] = s['nama_supplier']?.toString() ?? '-';
      }

      setState(() {
        _listPO = data.asMap().entries.map((entry) {
          final index = entry.key;
          final po = entry.value;
          final supplierId = po['supplier'] ?? '';
          return {
            ...po,
            'no': (index + 1).toString(),
            'supplier': supplierMap[supplierId] ?? supplierId,
          };
        }).toList();
        _filteredList = List.from(_listPO);
        _supplierMap = supplierMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================
  // SELESAI PEMBELIAN
  // =========================
  Future<void> _selesaikanPO(String idPembelian) async {
    try {
      await PembelianService.selesaiPembelian(idPembelian);

      await _fetchPembelian(); // refresh

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Status Diperbarui!',
          message: 'PO telah selesai.',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================
  // DELETE PEMBELIAN
  // =========================
  Future<void> _deletePO(String idPembelian) async {
    setState(() => _deletingId = idPembelian);

    try {
      await PembelianService.deletePembelian(idPembelian);

      setState(() {
        _listPO.removeWhere((po) => po['id'] == idPembelian);
        _filteredList.removeWhere((po) => po['id'] == idPembelian);
      });

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Data Berhasil Dihapus!',
          message: 'Data pembelian berhasil dihapus.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(_listPO);
      } else {
        _filteredList = _listPO.where((item) {
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
    _filteredList.sort((a, b) {
      int result;
      switch (ci) {
        case 1: result = (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? ''); break;
        case 2: result = (a['supplier']?.toString() ?? '').compareTo(b['supplier']?.toString() ?? ''); break;
        case 3: result = (a['tanggal']?.toString() ?? '').compareTo(b['tanggal']?.toString() ?? ''); break;
        case 4: result = (a['status']?.toString() ?? '').compareTo(b['status']?.toString() ?? ''); break;
        default: return 0;
      }
      return asc ? result : -result;
    });
  }

  //cetak pdf
  Future<void> _cetakPdf() async {
  try {
    if (_filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk dicetak')),
      );
      return;
    }

    final pdfBytes = await LaporanPembelianPdfService.generateLaporanPembelianPdf(
      items: _filteredList,
      startDate: _startDate,
      endDate: _endDate,
      status: _selectedStatus,
    );

    final filename = _startDate != null && _endDate != null
        ? 'data_pembelian_${LaporanPembelianPdfService.formatDate(_startDate)}_${LaporanPembelianPdfService.formatDate(_endDate)}.pdf'
        : 'data_pembelian.pdf';

    LaporanPembelianPdfService.downloadPdf(pdfBytes, filename);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal cetak PDF: $e'), backgroundColor: Colors.red),
    );
  }
}

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
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
      _fetchPembelian();
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

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedStatus,
          hint: const Text('Status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua')),
            DropdownMenuItem(value: 'Baru', child: Text('Baru')),
            DropdownMenuItem(value: 'Proses', child: Text('Proses')),
            DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
          ],
          onChanged: (val) {
            setState(() => _selectedStatus = val);
            _fetchPembelian();
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterList,
      decoration: InputDecoration(
        hintText: 'Cari ID Pembelian atau Nama Supplier...',
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
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Pembelian Barang'),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.inputPembelian),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Input Pembelian'),
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
                    _buildStatusDropdown(),
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
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.inputPembelian),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Input Pembelian'),
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
                      const SizedBox(width: 8),
                      _buildStatusDropdown(),
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

          // =========================
          // TABLE
          // =========================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(label: const Text('ID Pembelian'), onSort: _onSort),
                      DataColumn(label: const Text('Nama Supplier'), onSort: _onSort),
                      DataColumn(label: const Text('Tanggal Pembelian'), onSort: _onSort),
                      DataColumn(label: const Text('Status'), onSort: _onSort),
                      const DataColumn(label: Text('Action')),
                    ],
                    rows: _filteredList.map((po) {
                      return _buildDataRow(
                        context,
                        po['no'],
                        po['id'],
                        po['supplier'],
                        po['tanggal'],
                        po['status'],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BUILD ROW
  // =========================
  DataRow _buildDataRow(
    BuildContext context,
    String no,
    String idPembelian,
    String supplier,
    String tanggal,
    String status,
  ) {
    Color statusColor = switch (status) {
      'Baru' => Colors.blue,
      'Selesai' => Colors.green,
      _ => Colors.orange,
    };

    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(idPembelian, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(supplier)),
        DataCell(Text(tanggal)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoute.detailPembelian, arguments: idPembelian);
                },
              ),

              if (status == 'Baru') ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoute.editPembelian, arguments: idPembelian);
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.move_to_inbox_outlined, color: Colors.teal),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoute.inputPenerimaan, arguments: idPembelian);
                  },
                ),

                _deletingId == idPembelian
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => DeleteConfirmationDialog(
                              message: 'Hapus pembelian "$idPembelian"?',
                              onConfirmDelete: () {
                                _deletePO(idPembelian);
                              },
                            ),
                          );
                        },
                      ),
              ],

              if (status == 'Proses') ...[
                IconButton(
                  icon: const Icon(Icons.move_to_inbox_outlined, color: Colors.teal),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoute.inputPenerimaan, arguments: idPembelian);
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () {
                    _selesaikanPO(idPembelian);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}