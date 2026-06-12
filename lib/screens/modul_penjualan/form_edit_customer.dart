import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/customer_service.dart'; // nanti kamu buat service ini

class FormEditCustomer extends StatefulWidget {
  final int idCustomer;
  final String namaAwal;
  final String noHpAwal;
  final String alamatAwal;

  const FormEditCustomer({
    super.key,
    required this.idCustomer,
    required this.namaAwal,
    required this.noHpAwal,
    required this.alamatAwal,
  });

  @override
  State<FormEditCustomer> createState() => _FormEditCustomerState();
}

class _FormEditCustomerState extends State<FormEditCustomer> {
  late TextEditingController namaController;
  late TextEditingController noHpController;
  late TextEditingController alamatController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaAwal);
    noHpController = TextEditingController(text: widget.noHpAwal);
    alamatController = TextEditingController(text: widget.alamatAwal);
  }

  @override
  void dispose() {
    namaController.dispose();
    noHpController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
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
      await CustomerService.editCustomer(
        idCustomer: widget.idCustomer,
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
          title: 'Berhasil Diperbarui!',
          message: 'Data customer berhasil diperbarui.',
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ConfirmationDialog(
          isSuccess: false,
          title: 'Gagal Update',
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Edit Customer',
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
              _buildField(label: 'Nama Customer', controller: namaController),
              _buildField(label: 'No HP', controller: noHpController),
              _buildField(label: 'Alamat', controller: alamatController),
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
          onPressed: isLoading ? null : _submitEdit,
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
              : const Text('Simpan Perubahan'),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
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