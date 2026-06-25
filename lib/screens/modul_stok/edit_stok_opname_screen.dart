import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';

class EditStokOpnameScreen extends StatefulWidget {
  const EditStokOpnameScreen({super.key});

  @override
  State<EditStokOpnameScreen> createState() => _EditStokOpnameScreenState();
}

class _EditStokOpnameScreenState extends State<EditStokOpnameScreen> {
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9), 
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- JUDUL HALAMAN ---
          const GlobalAppBar(
            title: 'Edit Stok Opname',
          ),
          
          const SizedBox(height: 20),

          // ---TOMBOL KEMBALI ---
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoute.stokOpname);
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Kembali'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- HEADER INFORMASI  ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderInfo('Tanggal Stok Opname', '26 Okt 2023'),
                    _buildHeaderInfo('Petugas / PIC', 'Admin Putra'),
                    _buildHeaderInfo('ID Stok Opname', 'SO-20231026-001'),
                  ],
                ),
                
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 20),

                // --- SEARCH & TOMBOL SIMPAN PERUBAHAN ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari barang dalam daftar ini...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade50,
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
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Tampilkan konfirmasi berhasil
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const ConfirmationDialog(
                            isSuccess: true,
                            title: 'Perubahan Disimpan!',
                            message: 'Data stok opname telah berhasil diperbarui.',
                          ),
                        );

                        // Kembali ke utama setelah 2 detik
                        Future.delayed(const Duration(seconds: 2), () {
                          Navigator.pushReplacementNamed(context, AppRoute.stokOpname);
                        });
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- TABEL EDIT DATA ---
          Expanded(
            child: GlobalDataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                const DataColumn(label: Text('No')),
                DataColumn(
                  label: const Text('Nama Barang'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('Stok Sistem'),
                  onSort: _onSort,
                ),
                const DataColumn(label: Text('Stok Fisik (Edit)')),
                const DataColumn(label: Text('Keterangan')),
              ],
              rows: [
                _buildEditDataRow('1', 'Oli Mesin Matic', '150', '150', '-'),
                _buildEditDataRow('2', 'Busi Racing', '15', '13', '2 Hilang tercecer'),
                _buildEditDataRow('3', 'Kampas Rem Depan', '0', '0', '-'),
                _buildEditDataRow('4', 'Filter Udara', '42', '45', 'Kelebihan kirim'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
      ],
    );
  }

  DataRow _buildEditDataRow(String no, String nama, String stokSistem, String stokFisik, String ket) {
    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(nama)),
        DataCell(Text(stokSistem, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: stokFisik),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                filled: true,
                fillColor: Colors.orange.withOpacity(0.05), 
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 250,
            child: TextField(
              controller: TextEditingController(text: ket), 
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0 || columnIndex == 3 || columnIndex == 4) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortData();
    });
  }

  void _sortData() {
    if (_sortColumnIndex == null) return;
  }
}