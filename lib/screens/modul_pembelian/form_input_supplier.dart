import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/supplier_service.dart';

class FormInputSupplier extends StatefulWidget {
  const FormInputSupplier({super.key});

  @override
  State<FormInputSupplier> createState() => _FormInputSupplierState();
}

class _FormInputSupplierState extends State<FormInputSupplier> {

  final TextEditingController namaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();
  final TextEditingController leadTimeController = TextEditingController();

  bool isLoading = false;

  Future<void> handleSubmit() async {
    setState(() {
      isLoading = true;
    });

    try {
      await SupplierService.addSupplier({
        "nama_supplier": namaController.text,
        "alamat": alamatController.text,
        "no_telp": noHpController.text,
        "lead_time": int.tryParse(leadTimeController.text) ?? 0,
      });

      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Berhasil Disimpan!',
          message: 'Data supplier baru telah berhasil ditambahkan ke dalam database.',
        ),
      );

    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ConfirmationDialog(
          isSuccess: false,
          title: 'Gagal Menyimpan',
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.add_box_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Tambah Supplier Baru',
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
              _buildField(
                label: 'Nama Supplier',
                hint: 'Contoh: PT Maju Sejahtera',
                controller: namaController,
              ),
              _buildField(
                label: 'Alamat',
                hint: 'Masukkan alamat lengkap supplier',
                controller: alamatController,
              ),
              _buildField(
                label: 'No. HP / Telepon',
                hint: 'Contoh: 08123456789',
                isNumber: true,
                controller: noHpController,
              ),
              _buildField(
                label: 'Lead Time Supplier (Hari)',
                hint: '0',
                isNumber: true,
                controller: leadTimeController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Simpan Data'),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}