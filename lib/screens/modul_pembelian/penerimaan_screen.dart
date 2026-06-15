import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/table.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../service/penerimaan_service.dart';

class PenerimaanScreen extends StatefulWidget {
  const PenerimaanScreen({super.key});

  @override
  State<PenerimaanScreen> createState() => _PenerimaanScreenState();
}

class _PenerimaanScreenState extends State<PenerimaanScreen> {
  List<Map<String, dynamic>> _listPenerimaan = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String? _deletingId;
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
    _fetchPenerimaan();
  }

  Future<void> _fetchPenerimaan() async {
    try {
      String? startStr;
      String? endStr;
      if (_startDate != null) {
        startStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      }
      if (_endDate != null) {
        endStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      }

      final data = await PenerimaanService.getAllPenerimaan(
        limit: 999, startDate: startStr, endDate: endStr
      );

      List<Map<String, dynamic>> mapped = [];
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        mapped.add({
          "no": (i + 1).toString(),
          "id_pembelian": item['id_pembelian'],
          "tanggal": _formatTanggal(item['tanggal_penerimaan']),
          "id_penerimaan": item['id_penerimaan'],
          "created_at": item['created_at'],
        });
      }
      mapped.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      for (int i = 0; i < mapped.length; i++) {
        mapped[i]['no'] = (i + 1).toString();
        mapped[i].remove('created_at');
      }

      setState(() {
        _listPenerimaan = mapped;
        _filteredList = mapped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal load data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Future<void> _deletePenerimaan(String idPenerimaan) async {
    setState(() => _deletingId = idPenerimaan);
    try {
      await PenerimaanService.deletePenerimaan(idPenerimaan);
      setState(() {
        _listPenerimaan.removeWhere((po) => po['id_penerimaan'] == idPenerimaan);
        _filteredList.removeWhere((po) => po['id_penerimaan'] == idPenerimaan);
      });
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Data Berhasil Dihapus!',
          message: 'Data penerimaan berhasil dihapus.',
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
        _filteredList = List.from(_listPenerimaan);
      } else {
        _filteredList = _listPenerimaan.where((item) {
          return item.values.any((value) {
            return value.toString().toLowerCase().contains(query.toLowerCase());
          });
        }).toList();
      }
      _sortData();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0 || columnIndex == 4) return;
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
        case 1: result = (a['id_penerimaan']?.toString() ?? '').compareTo(b['id_penerimaan']?.toString() ?? ''); break;
        case 2: result = (a['id_pembelian']?.toString() ?? '').compareTo(b['id_pembelian']?.toString() ?? ''); break;
        case 3: result = (a['tanggal']?.toString() ?? '').compareTo(b['tanggal']?.toString() ?? ''); break;
        default: return 0;
      }
      return asc ? result : -result;
    });
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
      _fetchPenerimaan();
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
        hintText: 'Cari ID Penerimaan...',
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
          const GlobalAppBar(title: 'Penerimaan Barang'),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
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
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _buildDateField(controller: _startDateController, hint: 'Tgl Mulai', isStart: true)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildDateField(controller: _endDateController, hint: 'Tgl Akhir', isStart: false)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSearchField(),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GlobalDataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                const DataColumn(label: Text('No')),
                DataColumn(label: const Text('ID Penerimaan'), onSort: _onSort),
                DataColumn(label: const Text('ID Pembelian'), onSort: _onSort),
                DataColumn(label: const Text('Tanggal Terima'), onSort: _onSort),
                const DataColumn(label: Text('Action')),
              ],
              rows: _filteredList.map((po) {
                return _buildDataRow(
                  context,
                  po['no'] as String,
                  po['id_penerimaan'] as String,
                  po['id_pembelian'] as String,
                  po['tanggal'] as String,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    String no,
    String idPenerimaan,
    String idPembelian,
    String tanggal,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(idPenerimaan,
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(idPembelian,
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(tanggal)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
                tooltip: 'Lihat Detail Penerimaan',
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoute.detailPenerimaan,
                    arguments: idPenerimaan,
                  );
                },
                splashRadius: 20,
              ),
              if (_deletingId == idPenerimaan)
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Hapus Penerimaan',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => DeleteConfirmationDialog(
                        message: 'Hapus penerimaan "$idPenerimaan"?',
                        onConfirmDelete: () {
                          _deletePenerimaan(idPenerimaan);
                        },
                      ),
                    );
                  },
                  splashRadius: 20,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
