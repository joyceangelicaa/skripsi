import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/supplier_service.dart';

class FormEditSupplier extends StatefulWidget {
  final int idSupplier;
  final String namaAwal;
  final String alamatAwal;
  final String noHpAwal;
  final String leadTimeAwal;

  const FormEditSupplier({
    super.key,
    required this.idSupplier,
    required this.namaAwal,
    required this.alamatAwal,
    required this.noHpAwal,
    required this.leadTimeAwal,
  });

  @override
  State<FormEditSupplier> createState() => _FormEditSupplierState();
}

class _FormEditSupplierState extends State<FormEditSupplier> {

  late TextEditingController namaController;
  late TextEditingController alamatController;
  late TextEditingController noHpController;
  late TextEditingController leadTimeController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    namaController = TextEditingController(text: widget.namaAwal);
    alamatController = TextEditingController(text: widget.alamatAwal);
    noHpController = TextEditingController(text: widget.noHpAwal);
    leadTimeController = TextEditingController(text: widget.leadTimeAwal);
  }

  Future<void> handleUpdate() async {
    setState(() {
      isLoading = true;
    });

    try {
      await SupplierService.editSupplier({
        "id_supplier": widget.idSupplier,
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
          title: 'Perubahan Disimpan!',
          message: 'Data supplier telah berhasil diperbarui di dalam sistem.',
        ),
      );

    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ConfirmationDialog(
          isSuccess: false,
          title: 'Gagal Memperbarui',
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
          Icon(Icons.edit_note_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Edit Data Supplier',
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
              _buildField(label: 'Nama Supplier', controller: namaController),
              _buildField(label: 'Alamat', controller: alamatController),
              _buildField(label: 'No. HP / Telepon', controller: noHpController, isNumber: true),
              _buildField(label: 'Lead Time Supplier (Hari)', controller: leadTimeController, isNumber: true),
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
          onPressed: isLoading ? null : handleUpdate,
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
              : const Text('Simpan Perubahan'),
        ),
      ],
    );
  }

  //ditambahkan controller
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
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