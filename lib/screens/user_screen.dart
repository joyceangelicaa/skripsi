import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/table.dart';
import '../../service/user_service.dart';

import 'form_input_user.dart';
import 'form_edit_user.dart';
import 'form_detail_user.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List users = [];
  List _filteredUsers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    try {
      final data = await UserService.getAllUsers(limit: 999);
      setState(() {
        users = data;
        _filteredUsers = List.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat user: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(users);
      } else {
        _filteredUsers = users.where((u) {
          return u.values.any((value) {
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
    _filteredUsers.sort((a, b) {
      int result;
      switch (ci) {
        case 1:
          result = (a['nama_user'] ?? '').toString().compareTo(
              (b['nama_user'] ?? '').toString());
          break;
        case 2:
          result = (a['email'] ?? '').toString().compareTo(
              (b['email'] ?? '').toString());
          break;
        case 3:
          result = (a['role'] ?? '').toString().compareTo(
              (b['role'] ?? '').toString());
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
          const GlobalAppBar(title: 'Daftar User'),
          const SizedBox(height: 20),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => FormInputUser(
                      nextId: users.isEmpty
                          ? 1
                          : (users.map((u) => u['id_user'] as int).reduce((a, b) => a > b ? a : b)) + 1,
                    ),
                  );
                  fetchUsers();
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah User'),
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
                    hintText: 'Cari nama user...',
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
                      DataColumn(
                        label: const Text('Nama User'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Email'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Role'),
                        onSort: _onSort,
                      ),
                      const DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(_filteredUsers.length, (index) {
                      final u = _filteredUsers[index];

                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(u['nama_user'])),
                        DataCell(Text(u['email'])),
                        DataCell(Text(u['role'])),

                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // DETAIL
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => FormDetailUser(
                                    idUser: u['id_user'],
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
                                  builder: (_) => FormEditUser(
                                    idUser: u['id_user'],
                                    namaAwal: u['nama_user'],
                                    emailAwal: u['email'],
                                    passwordAwal: u['password'],
                                    roleAwal: u['role'],
                                  ),
                                );
                                fetchUsers();
                              },
                            ),

                            // DELETE
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DeleteConfirmationDialog(
                                    message: 'Hapus user ${u['nama_user']}?',
                                    onConfirmDelete: () async {
                                      try {
                                        await UserService.deleteUser(u['id_user']);

                                        showDialog(
                                          context: context,
                                          builder: (_) => const ConfirmationDialog(
                                            isSuccess: true,
                                            title: 'Berhasil',
                                            message: 'User berhasil dihapus',
                                          ),
                                        );

                                        fetchUsers();
                                      } catch (e) {
                                        showDialog(
                                          context: context,
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