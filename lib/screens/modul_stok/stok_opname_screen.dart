import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/table.dart';
import '../../service/stok_opname_service.dart'; 

class StokOpnameScreen extends StatefulWidget {
  const StokOpnameScreen({super.key});

  @override
  State<StokOpnameScreen> createState() => _StokOpnameScreenState();
}

class _StokOpnameScreenState extends State<StokOpnameScreen> {
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await StokOpnameService.getAllStokOpname();
      data.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      setState(() {
        _allData = data;
        _filteredData = List.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _refreshData() {
    setState(() => isLoading = true);
    fetchData();
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = List.from(_allData);
      } else {
        _filteredData = _allData.where((item) {
          return item.values.any((value) {
            return value.toString().toLowerCase().contains(query.toLowerCase());
          });
        }).toList();
      }
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
          const GlobalAppBar(title: 'Stok Opname'),
          const SizedBox(height: 20),

          // =========================
          // ACTION BAR (TIDAK DIUBAH)
          // =========================
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoute.inputStokOpname);
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah Stok Opname'),
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
                    hintText: 'Cari ID atau nama user...',
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
          // TABLE DATA (DINAMIS)
          // =========================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                    ? const Center(child: Text("Tidak ada data"))
                    : GlobalDataTable(
                        columns: const [
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('ID Stok Opname')),
                          DataColumn(label: Text('Tanggal Stok Opname')),
                          DataColumn(label: Text('Nama User')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: List.generate(_filteredData.length, (index) {
                          final item = _filteredData[index];

                          return _buildDataRow(
                            context,
                            (index + 1).toString(),
                            item['id_stok_opname'] ?? '-',
                            _formatTanggal(item['created_at']),
                            item['user']?['nama_user'] ?? '-',
                          );
                        }),
                      ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HELPER ROW (TIDAK DIUBAH UI)
  // =========================
  DataRow _buildDataRow(
      BuildContext context, String no, String idSO, String tanggal, String user) {
    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(idSO)),
        DataCell(Text(tanggal)),
        DataCell(Text(user)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // VIEW
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                tooltip: 'Lihat Detail',
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoute.detailStokOpname,
                    arguments: idSO, // ⬅️ KIRIM ID
                  );
                },
                splashRadius: 20,
              ),

              // EDIT
              // IconButton(
              //   icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              //   tooltip: 'Edit Data',
              //   onPressed: () {
              //     Navigator.pushReplacementNamed(
              //       context,
              //       AppRoute.editStokOpname,
              //       arguments: idSO,
              //     );
              //   },
              //   splashRadius: 20,
              // ),

              // // DELETE (masih dummy)
              // IconButton(
              //   icon: const Icon(Icons.delete_outline, color: Colors.red),
              //   tooltip: 'Hapus Data',
              //   onPressed: () {
              //     showDialog(
              //       context: context,
              //       builder: (BuildContext context) {
              //         return DeleteConfirmationDialog(
              //           message:
              //               'Apakah Anda yakin ingin menghapus data Stok Opname "$idSO"?',
              //           onConfirmDelete: () {
              //             bool hapusBerhasil = true;

              //             showDialog(
              //               context: context,
              //               barrierDismissible: false,
              //               builder: (context) => ConfirmationDialog(
              //                 isSuccess: hapusBerhasil,
              //                 title: hapusBerhasil
              //                     ? 'Berhasil Dihapus!'
              //                     : 'Gagal Menghapus',
              //                 message: hapusBerhasil
              //                     ? 'Data stok opname telah dihapus.'
              //                     : 'Terjadi kesalahan.',
              //               ),
              //             );
              //           },
              //         );
              //       },
              //     );
              //   },
              //   splashRadius: 20,
              // ),
            ],
          ),
        ),
      ],
    );
  }
}