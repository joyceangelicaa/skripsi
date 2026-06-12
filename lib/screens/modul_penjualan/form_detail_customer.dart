import 'package:flutter/material.dart';
import '../../../service/customer_service.dart';

class FormDetailCustomer extends StatefulWidget {
  final int idCustomer;

  const FormDetailCustomer({super.key, required this.idCustomer});

  @override
  State<FormDetailCustomer> createState() => _FormDetailCustomerState();
}

class _FormDetailCustomerState extends State<FormDetailCustomer> {
  Map<String, dynamic>? customer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  void fetchDetail() async {
    try {
      final data = await CustomerService.getDetailCustomer(widget.idCustomer);
      setState(() {
        customer = data;
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

    final c = customer;
    if (c == null) {
      return AlertDialog(
        content: const Text('Gagal memuat detail customer'),
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
            'Detail Customer',
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
              _buildReadOnlyField(label: 'Nama Customer', value: c['nama_customer'] ?? '-'),
              _buildReadOnlyField(label: 'No HP', value: c['no_telp']?.toString() ?? '-'),
              _buildReadOnlyField(label: 'Alamat', value: c['alamat'] ?? '-'),
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
