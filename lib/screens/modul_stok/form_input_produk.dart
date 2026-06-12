import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/produk_service.dart';

class FormInputProduk extends StatefulWidget {
  const FormInputProduk({super.key});

  @override
  State<FormInputProduk> createState() => _FormInputProdukState();
}

class _FormInputProdukState extends State<FormInputProduk> {
  final kodeController = TextEditingController();
  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final stokController = TextEditingController();
  final safetyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.add_box_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Tambah Produk Baru',
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
              _buildField(label: 'Kode Produk', hint: 'Contoh: BRG-001', controller: kodeController),
              _buildField(label: 'Nama Produk', hint: 'Masukkan nama barang', controller: namaController),
              _buildField(label: 'Harga Jual', hint: 'Masukkan harga jual', isNumber: true, controller: hargaController, prefix: 'Rp '),
              Row(
                children: [
                  Expanded(
                    child: _buildField(label: 'Stok', hint: 'Masukkan stok', isNumber: true, controller: stokController),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildField(label: 'Safety Stok', hint: 'Masukkan safety stok', isNumber: true, controller: safetyController),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
                if (kodeController.text.isEmpty ||
                    namaController.text.isEmpty ||
                    hargaController.text.isEmpty ||
                    stokController.text.isEmpty ||
                    safetyController.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => const ConfirmationDialog(
                      isSuccess: false,
                      title: 'Lengkapi Data',
                      message: 'Semua field harus diisi.',
                    ),
                  );
                  return;
                }
                try {
                  final harga = double.tryParse(hargaController.text);
                  final stok = int.tryParse(stokController.text);
                  final safety = int.tryParse(safetyController.text);
                  if (harga == null || stok == null || safety == null) {
                    showDialog(
                      context: context,
                      builder: (context) => const ConfirmationDialog(
                        isSuccess: false,
                        title: 'Format Salah',
                        message: 'Harga, Stok, dan Safety Stok harus berupa angka.',
                      ),
                    );
                    return;
                  }
                  await ProdukService.addProduk({
                    "kode_produk": kodeController.text,
                    "nama_produk": namaController.text,
                    "harga_jual": harga,
                    "stok_produk": stok,
                    "safety_stock": safety,
                  });
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const ConfirmationDialog(
                      isSuccess: true,
                      title: 'Berhasil Disimpan!',
                      message: 'Data produk baru telah berhasil ditambahkan ke dalam database stok.',
                    ),
                  );
                } catch (e) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => ConfirmationDialog(
                      isSuccess: false,
                      title: 'Gagal Menyimpan',
                      message: e.toString().replaceAll('Exception: ', ''),
                    ),
                  );
                }
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Simpan Produk'),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              prefixText: prefix,
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