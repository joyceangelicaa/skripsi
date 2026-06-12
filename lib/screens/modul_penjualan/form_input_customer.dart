import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/customer_service.dart'; // nanti kamu buat service ini

class FormInputCustomer extends StatefulWidget {
  const FormInputCustomer({super.key});

  @override
  State<FormInputCustomer> createState() => _FormInputCustomerState();
}

class _FormInputCustomerState extends State<FormInputCustomer> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  bool isLoading = false;

  Future<void> _submit() async {
    if (namaController.text.isEmpty ||
        noHpController.text.isEmpty ||
        alamatController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const ConfirmationDialog(
          isSuccess: false,
          title: 'Data Tidak Lengkap',
          message: 'Semua field wajib diisi.',
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await CustomerService.addCustomer(
        namaCustomer: namaController.text,
        noTelp: noHpController.text,
        alamat: alamatController.text,
      );

      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ConfirmationDialog(
          isSuccess: true,
          title: 'Berhasil Disimpan!',
          message: 'Data customer berhasil ditambahkan.',
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

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    namaController.dispose();
    noHpController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Tambah Customer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
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
                label: 'Nama Customer',
                controller: namaController,
              ),
              _buildField(
                label: 'No HP',
                controller: noHpController,
                isNumber: true,
              ),
              _buildField(
                label: 'Alamat',
                controller: alamatController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType:
                isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}