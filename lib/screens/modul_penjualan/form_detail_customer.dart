import 'package:flutter/material.dart';
import '../../../service/customer_service.dart';
import '../../../service/penjualan_service.dart';
import '../../../service/produk_service.dart';
import '../../global_widget/table.dart';

class FormDetailCustomer extends StatefulWidget {
  final int idCustomer;

  const FormDetailCustomer({super.key, required this.idCustomer});

  @override
  State<FormDetailCustomer> createState() => _FormDetailCustomerState();
}

class _FormDetailCustomerState extends State<FormDetailCustomer> {
  Map<String, dynamic>? customer;
  bool isLoadingCustomer = true;

  List<dynamic> penjualanList = [];
  bool isLoadingPenjualan = true;

  List<dynamic> produkList = [];
  bool isLoadingProduk = true;

  int? _sortColumnIndex1 = 1;
  bool _sortAscending1 = true;
  int? _sortColumnIndex2 = 1;
  bool _sortAscending2 = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
    fetchPenjualan();
    fetchProduk();
  }

  Future<void> fetchDetail() async {
    try {
      final data = await CustomerService.getDetailCustomer(widget.idCustomer);
      if (mounted) setState(() { customer = data; isLoadingCustomer = false; });
    } catch (e) {
      if (mounted) setState(() => isLoadingCustomer = false);
    }
  }

  Future<void> fetchPenjualan() async {
    try {
      final data = await PenjualanService.getPenjualanByCustomer(
        idCustomer: widget.idCustomer,
        limit: 999,
      );
      if (mounted) setState(() { penjualanList = data; isLoadingPenjualan = false; });
    } catch (e) {
      if (mounted) setState(() => isLoadingPenjualan = false);
    }
  }

  Future<void> fetchProduk() async {
    try {
      final data = await ProdukService.getProdukByCustomer(
        idCustomer: widget.idCustomer,
        limit: 999,
      );
      if (mounted) setState(() { produkList = data; isLoadingProduk = false; });
    } catch (e) {
      if (mounted) setState(() => isLoadingProduk = false);
    }
  }

  void _onSort1(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex1 = columnIndex;
      _sortAscending1 = ascending;
      _sortData1();
    });
  }

  void _sortData1() {
    if (_sortColumnIndex1 == null) return;
    final ci = _sortColumnIndex1!;
    final asc = _sortAscending1;
    penjualanList.sort((a, b) {
      int result;
      switch (ci) {
        case 1: result = (a['nomer_penjualan']?.toString() ?? '').compareTo(b['nomer_penjualan']?.toString() ?? ''); break;
        case 2: result = (a['tanggal_penjualan']?.toString() ?? '').compareTo(b['tanggal_penjualan']?.toString() ?? ''); break;
        case 3: result = ((a['total_harga'] ?? 0) as num).compareTo((b['total_harga'] ?? 0) as num); break;
        default: return 0;
      }
      return asc ? result : -result;
    });
  }

  void _onSort2(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex2 = columnIndex;
      _sortAscending2 = ascending;
      _sortData2();
    });
  }

  void _sortData2() {
    if (_sortColumnIndex2 == null) return;
    final ci = _sortColumnIndex2!;
    final asc = _sortAscending2;
    produkList.sort((a, b) {
      int result;
      switch (ci) {
        case 1: result = (a['nama_produk']?.toString() ?? '').compareTo(b['nama_produk']?.toString() ?? ''); break;
        case 2: result = (a['harga'] is List && (a['harga'] as List).isNotEmpty ? ((a['harga'] as List)[0] ?? 0) as num : 0).compareTo(b['harga'] is List && (b['harga'] as List).isNotEmpty ? ((b['harga'] as List)[0] ?? 0) as num : 0); break;
        case 3: result = (a['harga'] is List && (a['harga'] as List).length > 1 ? ((a['harga'] as List)[1] ?? 0) as num : 0).compareTo(b['harga'] is List && (b['harga'] as List).length > 1 ? ((b['harga'] as List)[1] ?? 0) as num : 0); break;
        case 4: result = (a['harga'] is List && (a['harga'] as List).length > 2 ? ((a['harga'] as List)[2] ?? 0) as num : 0).compareTo(b['harga'] is List && (b['harga'] as List).length > 2 ? ((b['harga'] as List)[2] ?? 0) as num : 0); break;
        default: return 0;
      }
      return asc ? result : -result;
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
            'Detail Customer',
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
                  Tab(text: 'Info Customer'),
                  Tab(text: 'Riwayat Penjualan'),
                  Tab(text: 'Riwayat Produk'),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(),
                    _buildPenjualanTab(),
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
    if (isLoadingCustomer) {
      return const Center(child: CircularProgressIndicator());
    }

    final c = customer;
    if (c == null) {
      return const Center(child: Text('Gagal memuat detail customer'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildReadOnlyField(label: 'Nama Customer', value: c['nama_customer']?.toString() ?? '-'),
          _buildReadOnlyField(label: 'No HP', value: c['no_telp']?.toString() ?? '-'),
          _buildReadOnlyField(label: 'Alamat', value: c['alamat'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildPenjualanTab() {
    if (isLoadingPenjualan) {
      return const Center(child: CircularProgressIndicator());
    }

    if (penjualanList.isEmpty) {
      return const Center(child: Text('Belum ada riwayat penjualan'));
    }

    return GlobalDataTable(
      sortColumnIndex: _sortColumnIndex1,
      sortAscending: _sortAscending1,
      columns: [
        const DataColumn(label: Text('No')),
        DataColumn(label: const Text('No. Penjualan'), onSort: _onSort1),
        DataColumn(label: const Text('Tanggal'), onSort: _onSort1),
        DataColumn(label: const Text('Total Harga'), onSort: _onSort1),
      ],
      rows: List.generate(penjualanList.length, (index) {
        final item = penjualanList[index];
        return DataRow(cells: [
          DataCell(Text('${index + 1}')),
          DataCell(Text(item['nomer_penjualan']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatTanggal(item['tanggal_penjualan']?.toString()))),
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
      sortColumnIndex: _sortColumnIndex2,
      sortAscending: _sortAscending2,
      columns: [
        const DataColumn(label: Text('No')),
        DataColumn(label: const Text('Produk'), onSort: _onSort2),
        DataColumn(label: const Text('Harga Terakhir'), onSort: _onSort2),
        DataColumn(label: const Text('Harga ke-2'), onSort: _onSort2),
        DataColumn(label: const Text('Harga ke-3'), onSort: _onSort2),
      ],
      rows: List.generate(produkList.length, (index) {
        final item = produkList[index];
        final harga = item['harga'] as List<dynamic>? ?? [];
        return DataRow(cells: [
          DataCell(Text('${index + 1}')),
          DataCell(Text(
              '${item['nama_produk']?.toString() ?? '-'} (${item['kode_produk']?.toString() ?? '-'})',
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
