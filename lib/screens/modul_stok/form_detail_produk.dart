import 'package:flutter/material.dart';
import '../../../service/produk_service.dart';

class FormDetailProduk extends StatefulWidget {
  final String kode;

  const FormDetailProduk({super.key, required this.kode});

  @override
  State<FormDetailProduk> createState() => _FormDetailProdukState();
}

class _FormDetailProdukState extends State<FormDetailProduk> {
  Map<String, dynamic>? produk;
  bool isLoading = true;

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
  void initState() {
    super.initState();
    fetchDetail();
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

    int stok = p['stok_produk'] ?? 0;
    int safety = p['safety_stock'] ?? 0;
    String status = "Tersedia";
    if (stok == 0) {
      status = "Habis";
    } else if (stok <= safety) {
      status = "Menipis";
    }

    Color statusColor = Colors.green;
    if (status == 'Menipis') statusColor = Colors.orange;
    if (status == 'Habis') statusColor = Colors.red;

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
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReadOnlyField(label: 'Kode Produk', value: p['kode_produk']?.toString() ?? '-'),
              _buildReadOnlyField(label: 'Nama Produk', value: p['nama_produk'] ?? '-'),
              _buildReadOnlyField(label: 'Harga Jual', value: _formatRupiah((p['harga_jual'] ?? 0).toDouble())),
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField(label: 'Stok', value: stok.toString())),
                  const SizedBox(width: 20),
                  Expanded(child: _buildReadOnlyField(label: 'Safety Stok', value: safety.toString())),
                ],
              ),
              _buildReadOnlyField(
                label: 'Status',
                valueWidget: Container(
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
                    ),
                  ),
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
