import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/table.dart';

import '../../service/customer_service.dart';

import 'form_input_customer.dart';
import 'form_edit_customer.dart';
import 'form_detail_customer.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<dynamic> customers = [];
  List<dynamic> _filteredCustomers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchCustomer();
  }

  // ================= GET DATA =================
  Future<void> fetchCustomer() async {
    setState(() => isLoading = true);

    try {
      final data = await CustomerService.getAllCustomer(limit: 500, offset: 0);
      setState(() {
        customers = data;
        _filteredCustomers = List.from(data);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat customer: ${e.toString().replaceAll('Exception: ', '')}"),
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
        _filteredCustomers = List.from(customers);
      } else {
        _filteredCustomers = customers.where((item) {
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
    _filteredCustomers.sort((a, b) {
      int result;
      switch (ci) {
        case 1:
          result = (a['nama_customer'] ?? '').toString().compareTo(
              (b['nama_customer'] ?? '').toString());
          break;
        case 2:
          result = (a['no_telp'] ?? '').toString().compareTo(
              (b['no_telp'] ?? '').toString());
          break;
        case 3:
          result = (a['alamat'] ?? '').toString().compareTo(
              (b['alamat'] ?? '').toString());
          break;
        default:
          return 0;
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
          const GlobalAppBar(title: 'Daftar Customer'),
          const SizedBox(height: 20),

          // ================= ACTION =================
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const FormInputCustomer(),
                  );
                  fetchCustomer();
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah Customer'),
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
                    hintText: 'Cari customer...',
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

          // ================= TABLE =================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(
                        label: const Text('Nama'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('No HP'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Alamat'),
                        onSort: _onSort,
                      ),
                      const DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(_filteredCustomers.length, (index) {
                      final c = _filteredCustomers[index];

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(c['nama_customer'])),
                          DataCell(Text(c['no_telp'])),
                          DataCell(Text(c['alamat'])),

                          DataCell(
                            Row(
                              children: [
                                // ===== DETAIL =====
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.purple),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => FormDetailCustomer(
                                        idCustomer: c['id_customer'],
                                      ),
                                    );
                                  },
                                ),

                                // ===== EDIT =====
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => FormEditCustomer(
                                        idCustomer: c['id_customer'],
                                        namaAwal: c['nama_customer'],
                                        noHpAwal: c['no_telp'],
                                        alamatAwal: c['alamat'],
                                      ),
                                    );
                                    fetchCustomer();
                                  },
                                ),

                                // ===== DELETE =====
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => DeleteConfirmationDialog(
                                        message: 'Hapus ${c['nama_customer']}?',
                                        onConfirmDelete: () async {
                                          try {
                                            await CustomerService.deleteCustomer(c['id_customer']);

                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => const ConfirmationDialog(
                                                isSuccess: true,
                                                title: 'Berhasil Dihapus!',
                                                message: 'Data customer berhasil dihapus.',
                                              ),
                                            );

                                            fetchCustomer();
                                          } catch (e) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => ConfirmationDialog(
                                                isSuccess: false,
                                                title: 'Gagal Menghapus',
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
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}