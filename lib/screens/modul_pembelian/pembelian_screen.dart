import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/table.dart';
import '../../root/app_route.dart';
import '../../service/pembelian_service.dart';
import '../../service/supplier_service.dart';

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
  final TextEditingController _searchController = TextEditingController();

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
      final results = await Future.wait([
        PembelianService.getAllPembelian(limit: 999),
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
          const GlobalAppBar(title: 'Pembelian Barang'),

          const SizedBox(height: 20),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoute.inputPembelian);
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Input Pembelian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
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
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // =========================
          // TABLE
          // =========================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('ID Pembelian')),
                      DataColumn(label: Text('Nama Supplier')),
                      DataColumn(label: Text('Tanggal Pembelian')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
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
    Color statusColor = status == 'Selesai' ? Colors.green : Colors.orange;

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

              if (status == 'Proses') ...[
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