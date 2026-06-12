import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/table.dart';
import '../../service/reorder_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> rekomendasiList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      final result = await ReorderService.getRekomendasi(limit: 500, offset: 0);
      setState(() {
        rekomendasiList = result['items'] as List<dynamic>;
        isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data: ${e.toString().replaceAll('Exception: ', '')}"),
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
          const GlobalAppBar(title: 'Dashboard'),
          const SizedBox(height: 30),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Nama Barang')),
                      DataColumn(label: Text('Jumlah Stok')),
                      DataColumn(label: Text('Nilai ROP')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: rekomendasiList.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      var produk = item['produk'] as Map<String, dynamic>;

                      int stok = produk['stok_produk'] ?? 0;
                      String statusLabel = item['status'] == 'PERLU_REORDER' ? 'Perlu Reorder' : 'Aman';

                      return _buildDataRow(
                        (index + 1).toString(),
                        produk['nama_produk'] ?? '-',
                        stok.toString(),
                        produk['reorder_point']?.toString() ?? '0',
                        statusLabel,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String no, String nama, String stok, String rop, String status) {
    Color statusColor = status == 'Perlu Reorder' ? Colors.red : Colors.green;

    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(nama)),
        DataCell(Text(stok)),
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
      ],
    );
  }
}
