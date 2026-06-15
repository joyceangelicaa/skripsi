import 'package:flutter/material.dart';
import '../../../service/supplier_service.dart';
import '../../../service/pembelian_service.dart';
import '../../../service/produk_service.dart';
import '../../../global_widget/table.dart';

class FormDetailSupplier extends StatefulWidget {
  final int idSupplier;

  const FormDetailSupplier({super.key, required this.idSupplier});

  @override
  State<FormDetailSupplier> createState() => _FormDetailSupplierState();
}

class _FormDetailSupplierState extends State<FormDetailSupplier> {
  Map<String, dynamic>? supplier;
  bool isLoadingSupplier = true;

  List<dynamic> pembelianList = [];
  bool isLoadingPembelian = true;

  List<dynamic> produkList = [];
  bool isLoadingProduk = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
    fetchPembelian();
    fetchProduk();
  }

  Future<void> fetchDetail() async {
    try {
      final data = await SupplierService.getDetailSupplier(widget.idSupplier);
      if (mounted) setState(() { supplier = data; isLoadingSupplier = false; });
    } catch (e) {
      if (mounted) setState(() => isLoadingSupplier = false);
    }
  }

  Future<void> fetchPembelian() async {
    try {
      final data = await PembelianService.getPembelianBySupplier(
        idSupplier: widget.idSupplier,
        limit: 999,
      );
      if (mounted) setState(() { pembelianList = data; isLoadingPembelian = false; });
    } catch (e) {
      if (mounted) setState(() => isLoadingPembelian = false);
    }
  }

  Future<void> fetchProduk() async {
    try {
      final data = await ProdukService.getProdukBySupplier(
        idSupplier: widget.idSupplier,
        limit: 999,
      );
      if (mounted) setState(() { produkList = data; isLoadingProduk = false; });
    } catch (e) {
      if (mounted) setState(() => isLoadingProduk = false);
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

  String _formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    final value = num.tryParse(number.toString()) ?? 0;
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Detail Data Supplier',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 800,
        height: 500,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFF1E293B),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF1E293B),
                tabs: [
                  Tab(text: 'Info Supplier'),
                  Tab(text: 'Riwayat Pembelian'),
                  Tab(text: 'Riwayat Produk'),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(),
                    _buildPembelianTab(),
                    _buildProdukTab(),
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

  Widget _buildInfoTab() {
    if (isLoadingSupplier) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = supplier;
    if (s == null) {
      return const Center(child: Text('Gagal memuat detail supplier'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildReadOnlyField(label: 'Nama Supplier', value: s['nama_supplier']?.toString() ?? '-'),
          _buildReadOnlyField(label: 'Alamat', value: s['alamat'] ?? '-'),
          _buildReadOnlyField(label: 'No. HP / Telepon', value: s['no_telp']?.toString() ?? '-'),
          _buildReadOnlyField(label: 'Lead Time Supplier', value: '${s['lead_time']?.toString() ?? '0'} Hari'),
        ],
      ),
    );
  }

  Widget _buildPembelianTab() {
    if (isLoadingPembelian) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pembelianList.isEmpty) {
      return const Center(child: Text('Belum ada riwayat pembelian'));
    }

    return GlobalDataTable(
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('ID Pembelian')),
        DataColumn(label: Text('Tanggal')),
        DataColumn(label: Text('Total Harga')),
      ],
      rows: List.generate(pembelianList.length, (index) {
        final item = pembelianList[index];
        return DataRow(cells: [
          DataCell(Text('${index + 1}')),
          DataCell(Text(item['id_pembelian']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatTanggal(item['tanggal_pembelian']?.toString()))),
          DataCell(Text(_formatRupiah(item['total_harga']))),
        ]);
      }),
    );
  }

  Widget _buildProdukTab() {
    if (isLoadingProduk) {
      return const Center(child: CircularProgressIndicator());
    }

    if (produkList.isEmpty) {
      return const Center(child: Text('Belum ada riwayat produk'));
    }

    return GlobalDataTable(
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Nama Produk')),
        DataColumn(label: Text('Harga Terakhir')),
        DataColumn(label: Text('Harga ke-2')),
        DataColumn(label: Text('Harga ke-3')),
      ],
      rows: List.generate(produkList.length, (index) {
        final item = produkList[index];
        final harga = item['harga'] as List<dynamic>? ?? [];
        return DataRow(cells: [
          DataCell(Text('${index + 1}')),
          DataCell(Text(item['nama_produk']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(harga.isNotEmpty ? _formatRupiah(harga[0]) : 'Rp 0')),
          DataCell(Text(harga.length > 1 ? _formatRupiah(harga[1]) : 'Rp 0')),
          DataCell(Text(harga.length > 2 ? _formatRupiah(harga[2]) : 'Rp 0')),
        ]);
      }),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
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
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}