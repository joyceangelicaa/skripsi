import 'package:flutter/material.dart';
import '../../../service/produk_service.dart';
import '../../../global_widget/table.dart';

class FormDetailProduk extends StatefulWidget {
  final String kode;

  const FormDetailProduk({super.key, required this.kode});

  @override
  State<FormDetailProduk> createState() => _FormDetailProdukState();
}

class _FormDetailProdukState extends State<FormDetailProduk> {
  Map<String, dynamic>? produk;
  bool isLoading = true;

  List<dynamic> suppliers = [];
  bool isLoadingSuppliers = true;

  List<Map<String, dynamic>> batches = [];
  bool isLoadingBatches = true;

  String _formatRupiah(num value) {
    final str = value.toStringAsFixed(0).split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
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
  void initState() {
    super.initState();
    fetchDetail();
    fetchSuppliers();
    fetchBatches();
  }

  void fetchDetail() async {
    try {
      final data = await ProdukService.getDetailProduk(widget.kode);
      setState(() {
        produk = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void fetchSuppliers() async {
    try {
      final data = await ProdukService.getSupplierByProduk(
        kodeProduk: widget.kode,
      );
      setState(() {
        suppliers = data;
        isLoadingSuppliers = false;
      });
    } catch (e) {
      setState(() => isLoadingSuppliers = false);
    }
  }

  void fetchBatches() async {
    try {
      final data = await ProdukService.getBatchByKodeProduk(
        kodeProduk: widget.kode,
      );
      setState(() {
        batches = data;
        isLoadingBatches = false;
      });
    } catch (e) {
      setState(() => isLoadingBatches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(
          width: 500,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final p = produk;
    if (p == null) {
      return AlertDialog(
        content: const Text('Gagal memuat detail produk'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Detail Produk',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 800,
        height: 500,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFF1E293B),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF1E293B),
                tabs: [
                  Tab(text: 'Info Produk'),
                  Tab(text: 'Batch'),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(p!),
                    _buildBatchTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildInfoTab(Map<String, dynamic> p) {
    int stok = p['stok_produk'] ?? 0;
    int safety = p['safety_stock'] ?? 0;
    String status = "Tersedia";
    if (stok == 0) {
      status = "Habis";
    } else if (stok <= safety) {
      status = "Menipis";
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyField(label: 'Kode Produk', value: p['kode_produk']?.toString() ?? '-'),
          _buildReadOnlyField(label: 'Nama Produk', value: p['nama_produk'] ?? '-'),
          _buildReadOnlyField(label: 'Harga Jual', value: _formatRupiah((p['harga_jual'] ?? 0).toDouble())),
          Row(
            children: [
              Expanded(child: _buildReadOnlyField(label: 'Stok', value: stok.toString())),
              const SizedBox(width: 20),
              Expanded(child: _buildReadOnlyField(label: 'Safety Stok', value: safety.toString())),
              const SizedBox(width: 20),
              Expanded(child: _buildReadOnlyField(label: 'Status', value: status)),
            ],
          ),
          if (!isLoadingSuppliers) ...[
            const SizedBox(height: 10),
            _buildSupplierSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchTab() {
    if (isLoadingBatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (batches.isEmpty) {
      return const Center(child: Text('Belum ada data batch'));
    }

    return GlobalDataTable(
      columns: const [
        DataColumn(label: Text('Batch')),
        DataColumn(label: Text('Tanggal Batch')),
        DataColumn(label: Text('Total Stok')),
        DataColumn(label: Text('Sisa Stok')),
      ],
      rows: List.generate(batches.length, (index) {
        final item = batches[index];
        return DataRow(cells: [
          DataCell(Text(item['kode_batch']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatTanggal(item['tanggal_masuk']?.toString()))),
          DataCell(Text('${item['total_stok'] ?? 0}')),
          DataCell(Text('${item['sisa_stok'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w600))),
        ]);
      }),
    );
  }

  Widget _buildSupplierSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3 Supplier Terakhir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          if (suppliers.isEmpty)
            const Text('Belum ada riwayat supplier',
                style: TextStyle(fontSize: 14, color: Colors.grey))
          else
            Row(
              children: [
                for (int i = 0; i < suppliers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        suppliers[i]['nama_supplier']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: valueWidget ?? Text(
              value ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
