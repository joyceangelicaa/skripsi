import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import 'form_input_produk.dart';
import 'form_edit_produk.dart';
import 'form_detail_produk.dart';
import '../../global_widget/delete_confirmation_dialog.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../global_widget/table.dart';
import '../../service/produk_service.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  List<dynamic> produkList = [];
  List<dynamic> _filteredProduk = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  void fetchProduk() async {
    try {
      final data = await ProdukService.getAllProduk(limit: 999, offset: 0);
      data.sort((a, b) => (a['nama_produk'] ?? '').toString().compareTo((b['nama_produk'] ?? '').toString()));
      setState(() {
        produkList = data;
        _filteredProduk = List.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat produk: ${e.toString().replaceAll('Exception: ', '')}"),
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
        _filteredProduk = List.from(produkList);
      } else {
        _filteredProduk = produkList.where((item) {
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

  String _formatRupiah(num value) {
    final str = value.toStringAsFixed(0).split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(
            title: 'Daftar Produk',
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const FormInputProduk(),
                  );
                  fetchProduk(); // 🔥 refresh
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah Produk'),
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
                    hintText: 'Cari nama barang...',
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
                          DataColumn(label: Text('Nama Barang')),
                          DataColumn(label: Text('Jumlah Stock')),
                          DataColumn(label: Text('Harga Jual')),
                          DataColumn(label: Text('ROP')),
                          DataColumn(label: Text('Status Barang')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: _filteredProduk.asMap().entries.map((entry) {
                          int index = entry.key;
                          var item = entry.value;

                          String status = "Tersedia";
                          if (item['stok_produk'] == 0) {
                            status = "Habis";
                          } else if (item['stok_produk'] <= item['reorder_point']) {
                            status = "Menipis";
                          }

                          return _buildDataRow(
                            context,
                            (index + 1).toString(),
                            item['nama_produk'],
                            item['stok_produk'].toString(),
                            _formatRupiah((item['harga_jual'] ?? 0).toDouble()),
                            item['reorder_point'].toString(),
                            status,
                            item,
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
    String nama,
    String stok,
    String harga,
    String rop,
    String status,
    dynamic item,
  ) {
    Color statusColor = Colors.green;
    if (status == 'Menipis') statusColor = Colors.orange;
    if (status == 'Habis') statusColor = Colors.red;

    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(nama)),
        DataCell(Text(stok)),
        DataCell(Text(harga)),
        DataCell(Text(rop)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FormDetailProduk(
                      kode: item['kode_produk'],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => FormEditProduk(
                      kodeAwal: item['kode_produk'],
                      namaAwal: item['nama_produk'],
                      hargaAwal: item['harga_jual'].toString(),
                      stokAwal: item['stok_produk'].toString(),
                      safetyStokAwal: item['safety_stock'].toString(),
                    ),
                  );
                  fetchProduk();
                },
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined, color: Colors.teal),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoute.detailKartuStok,
                    arguments: item['kode_produk'],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DeleteConfirmationDialog(
                      message: 'Apakah Anda yakin ingin menghapus produk "$nama"?',
                      onConfirmDelete: () async {
                        try {
                          await ProdukService.deleteProduk(item['kode_produk']);
                          fetchProduk();

                          showDialog(
                            context: context,
                            builder: (_) => const ConfirmationDialog(
                              isSuccess: true,
                              title: 'Berhasil Dihapus!',
                              message: 'Data produk telah dihapus.',
                            ),
                          );
                        } catch (e) {
                          showDialog(
                            context: context,
                            builder: (_) => const ConfirmationDialog(
                              isSuccess: false,
                              title: 'Gagal Menghapus',
                              message: 'Terjadi kesalahan.',
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