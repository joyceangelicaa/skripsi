import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../root/app_route.dart';
import '../../global_widget/table.dart';
import '../../service/kartu_stok_service.dart';

class KartuStokScreen extends StatefulWidget {
  const KartuStokScreen({super.key});

  @override
  State<KartuStokScreen> createState() => _KartuStokScreenState();
}

class _KartuStokScreenState extends State<KartuStokScreen> {
  List<dynamic> kartuStokList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKartuStok();
  }

  void fetchKartuStok() async {
    try {
      final data = await KartuStokService.getAllKartuStok();

      setState(() {
        kartuStokList = data;
        isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal memuat kartu stok: ${e.toString().replaceAll('Exception: ', '')}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Kartu Stok'),

          const SizedBox(height: 20),

          // =========================
          // SEARCH (TIDAK DIUBAH UI)
          // =========================
          Row(
            children: [
              Expanded(
                child: TextField(
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

          // =========================
          // TABLE
          // =========================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Nama Barang')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: kartuStokList.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;

                      final namaBarang =
                          item['produk']?['nama_produk'] ??
                          item['kode_produk'] ??
                          '-';

                      return _buildDataRow(
                        context,
                        (index + 1).toString(),
                        namaBarang,
                        item,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================
  // ROW BUILDER (SAMA KAYA PUNYA KAMU)
  // =========================
  DataRow _buildDataRow(
    BuildContext context,
    String no,
    String nama,
    dynamic item,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(nama)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.teal),
            tooltip: 'Lihat Detail Kartu Stok',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoute.detailKartuStok,
                arguments: item['kode_produk'], // 🔥 penting
              );
            },
            splashRadius: 20,
          ),
        ),
      ],
    );
  }
}