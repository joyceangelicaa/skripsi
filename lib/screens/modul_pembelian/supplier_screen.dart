import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/table.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import 'form_input_supplier.dart'; 
import 'form_edit_supplier.dart';
import 'form_detail_supplier.dart';
import '../../service/supplier_service.dart'; // <-- PENTING

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {

  List suppliers = [];
  List _filteredSuppliers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchSupplier();
  }

  Future<void> fetchSupplier() async {
    try {
      final data = await SupplierService.getAllSuppliers(limit: 999, offset: 0);
      setState(() {
        suppliers = data;
        _filteredSuppliers = List.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat supplier: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = List.from(suppliers);
      } else {
        _filteredSuppliers = suppliers.where((item) {
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
    _filteredSuppliers.sort((a, b) {
      int result;
      switch (ci) {
        case 1: result = (a['nama_supplier']?.toString() ?? '').compareTo(b['nama_supplier']?.toString() ?? ''); break;
        case 2: result = (a['no_telp']?.toString() ?? '').compareTo(b['no_telp']?.toString() ?? ''); break;
        case 3: result = (a['alamat']?.toString() ?? '').compareTo(b['alamat']?.toString() ?? ''); break;
        default: return 0;
      }
      return asc ? result : -result;
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
          const GlobalAppBar(title: 'Daftar Supplier'),

          const SizedBox(height: 20),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const FormInputSupplier(),
                  );

                  fetchSupplier(); // refresh setelah tambah
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah Supplier'),
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
                    hintText: 'Cari nama supplier atau alamat...',
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
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(label: const Text('Nama Supplier'), onSort: _onSort),
                      DataColumn(label: const Text('No Telpon'), onSort: _onSort),
                      DataColumn(label: const Text('Alamat'), onSort: _onSort),
                      const DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(_filteredSuppliers.length, (index) {
                      final s = _filteredSuppliers[index];
                      return _buildDataRow(
                        context,
                        index + 1,
                        s,
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, int no, dynamic s) {
    return DataRow(
      cells: [
        DataCell(Text(no.toString())),
        DataCell(Text(s['nama_supplier'] ?? '')),
        DataCell(Text(s['no_telp'] ?? '')),
        DataCell(Text(s['alamat'] ?? '', overflow: TextOverflow.ellipsis)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // VIEW
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FormDetailSupplier(
                      idSupplier: s['id_supplier'],
                    ),
                  );
                },
              ),

              // EDIT
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => FormEditSupplier(
                      idSupplier: s['id_supplier'],
                      namaAwal: s['nama_supplier'],
                      alamatAwal: s['alamat'],
                      noHpAwal: s['no_telp'],
                      // leadTimeAwal: s['lead_time'].toString(),
                    ),
                  );

                  fetchSupplier(); // refresh setelah edit
                },
              ),

              // DELETE
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DeleteConfirmationDialog(
                      message: 'Apakah Anda yakin ingin menghapus supplier "${s['nama_supplier']}"?',
                      onConfirmDelete: () async {
                        try {
                          await SupplierService.deleteSupplier(s['id_supplier']);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const ConfirmationDialog(
                              isSuccess: true,
                              title: 'Berhasil Dihapus!',
                              message: 'Data supplier telah dihapus.',
                            ),
                          );

                          fetchSupplier();
                        } catch (e) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => ConfirmationDialog(
                              isSuccess: false,
                              title: 'Gagal',
                              message: e.toString().replaceAll('Exception: ', ''),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}