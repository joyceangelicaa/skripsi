import 'package:flutter/material.dart';
import '../../../service/supplier_service.dart';

class FormDetailSupplier extends StatefulWidget {
  final int idSupplier;

  const FormDetailSupplier({super.key, required this.idSupplier});

  @override
  State<FormDetailSupplier> createState() => _FormDetailSupplierState();
}

class _FormDetailSupplierState extends State<FormDetailSupplier> {
  Map<String, dynamic>? supplier;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  void fetchDetail() async {
    try {
      final data = await SupplierService.getDetailSupplier(widget.idSupplier);
      setState(() {
        supplier = data;
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

    final s = supplier;
    if (s == null) {
      return AlertDialog(
        content: const Text('Gagal memuat detail supplier'),
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
            'Detail Data Supplier',
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
              _buildReadOnlyField(label: 'Nama Supplier', value: s['nama_supplier']?.toString() ?? '-'),
              _buildReadOnlyField(label: 'Alamat', value: s['alamat'] ?? '-'),
              _buildReadOnlyField(label: 'No. HP / Telepon', value: s['no_telp']?.toString() ?? '-'),
              _buildReadOnlyField(label: 'Lead Time Supplier', value: '${s['lead_time']?.toString() ?? '0'} Hari'),
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
