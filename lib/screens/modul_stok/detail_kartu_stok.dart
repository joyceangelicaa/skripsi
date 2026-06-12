import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';
import '../../service/kartu_stok_service.dart';
import '../../service/produk_service.dart';

class DetailKartuStokScreen extends StatefulWidget {
  const DetailKartuStokScreen({super.key});

  @override
  State<DetailKartuStokScreen> createState() =>
      _DetailKartuStokScreenState();
}

class _DetailKartuStokScreenState extends State<DetailKartuStokScreen> {
  List<dynamic> data = [];
  bool isLoading = true;

  String kodeProduk = "";
  String namaBarang = "-";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      kodeProduk = args as String;
      fetchData();
    }
  }

  void fetchData() async {
    try {
      final result =
          await KartuStokService.getKartuStokByProduk(kodeProduk: kodeProduk);

      setState(() {
        data = result;

        // ambil nama barang dari data pertama
        if (result.isNotEmpty) {
          namaBarang =
              result[0]['produk']?['nama_produk'] ?? '-';
        } else {
          _loadNamaProduk();
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal memuat detail: ${e.toString().replaceAll('Exception: ', '')}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadNamaProduk() async {
    try {
      final detail = await ProdukService.getDetailProduk(kodeProduk);
      if (mounted) {
        setState(() {
          namaBarang = detail['nama_produk'] ?? '-';
        });
      }
    } catch (_) {}
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
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // TITLE
          // =========================
          const GlobalAppBar(
            title: 'Detail Kartu Stok',
          ),

          const SizedBox(height: 20),

          // =========================
          // BUTTON BACK
          // =========================
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoute.produk,
              );
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Kembali'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // INFO BOX (BALIK NORMAL)
          // =========================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildInfoItem('Nama Barang', namaBarang),
                const SizedBox(width: 50),
                _buildInfoItem('Kode Barang', kodeProduk),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // =========================
          // TABLE
          // =========================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Nama Barang')),
                      DataColumn(label: Text('Keterangan')),
                      DataColumn(label: Text('Qty Masuk')),
                      DataColumn(label: Text('Qty Keluar')),
                      DataColumn(label: Text('Sisa Stok')),
                    ],
                    rows: data.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(_formatTanggal(item['created_at']))),
                          DataCell(Text(
                              item['produk']?['nama_produk'] ?? '-')),
                          DataCell(Text(item['keterangan_barang'] ?? '-')),
                          DataCell(Text(
                            item['stok_masuk'].toString(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                          DataCell(Text(
                            item['stok_keluar'].toString(),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                          DataCell(Text(
                            item['stok_barang'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HELPER INFO
  // =========================
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}