import 'package:flutter/material.dart';
import '../../global_widget/app_bar.dart';
import '../../global_widget/table.dart';
import '../../root/app_route.dart';
import '../../service/penerimaan_service.dart';

class PenerimaanScreen extends StatefulWidget {
  const PenerimaanScreen({super.key});

  @override
  State<PenerimaanScreen> createState() => _PenerimaanScreenState();
}

class _PenerimaanScreenState extends State<PenerimaanScreen> {
  List<Map<String, dynamic>> _listSelesai = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPenerimaan();
  }

  Future<void> _fetchPenerimaan() async {
    try {
      final data = await PenerimaanService.getAllPenerimaan(
        status: "selesai", limit: 999
      );

      List<Map<String, dynamic>> mapped = [];

      for (int i = 0; i < data.length; i++) {
        final item = data[i];

        mapped.add({
          "no": (i + 1).toString(),
          "id": item['id_pembelian'],
          "tanggal": _formatTanggal(item['tanggal_penerimaan']),
          "status": item['status'] ?? '-',
          "id_penerimaan": item['id_penerimaan'], // penting untuk detail
          "created_at": item['created_at'],
        });
      }
      mapped.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));

      for (int i = 0; i < mapped.length; i++) {
        mapped[i]['no'] = (i + 1).toString();
        mapped[i].remove('created_at');
      }

      setState(() {
        _listSelesai = mapped;
        _filteredList = mapped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal load data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';

    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(_listSelesai);
      } else {
        _filteredList = _listSelesai.where((item) {
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
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Penerimaan Barang'),
          const SizedBox(height: 20),

          // --- SEARCH BAR ---
          TextField(
            controller: _searchController,
            onChanged: _filterList,
            decoration: InputDecoration(
              hintText: 'Cari ID Penerimaan...',
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

          const SizedBox(height: 20),

          // --- TABEL DATA ---
          Expanded(
            child: GlobalDataTable(
              columns: const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('ID Penerimaan')),
                DataColumn(label: Text('ID Pembelian')),
                DataColumn(label: Text('Tanggal Terima')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: _filteredList.map((po) {
                return _buildDataRow(
                  context,
                  po['no'] as String,
                  po['id_penerimaan'] as String,
                  po['id'] as String,
                  po['tanggal'] as String,
                  po['status'] as String,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER TABEL (UI TIDAK DIUBAH) ---
  DataRow _buildDataRow(
    BuildContext context,
    String no,
    String idPenerimaan,
    String idPembelian,
    String tanggal,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(no)),
        DataCell(Text(idPenerimaan,
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(idPembelian,
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(tanggal)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Selesai',
              style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.purple),
            tooltip: 'Lihat Detail Penerimaan',
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoute.detailPenerimaan,
                arguments: idPenerimaan, // 🔥 kirim ID ke detail
              );
            },
            splashRadius: 20,
          ),
        ),
      ],
    );
  }
}