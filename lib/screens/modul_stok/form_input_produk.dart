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

  Map<String, dynamic>? _saranSafety;
  bool _isLoadingSaran = false;
  List<Map<String, dynamic>> _allProduk = [];
  bool _isLoadingProduk = false;

  Future<void> _fetchAllProduk() async {
    setState(() => _isLoadingProduk = true);
    try {
      final data = await ProdukService.getAllProduk(limit: 999, offset: 0);
      if (mounted) setState(() { _allProduk = data.cast<Map<String, dynamic>>(); _isLoadingProduk = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingProduk = false);
    }
  }

  void _onNamaChanged(String nama) {
    if (nama.trim().isEmpty) {
      setState(() { _saranSafety = null; _isLoadingSaran = false; });
      return;
    }
    if (_allProduk.isEmpty && !_isLoadingProduk) _fetchAllProduk();
    final match = _allProduk.where((p) =>
      (p['nama_produk'] as String).toLowerCase().contains(nama.toLowerCase())
    ).toList();
    if (match.isNotEmpty) {
      _fetchSaranSafety(match.first['kode_produk'] as String);
    } else {
      setState(() { _saranSafety = null; _isLoadingSaran = false; });
    }
  }

  Future<void> _fetchSaranSafety(String kode) async {
    if (kode.isEmpty) { setState(() { _saranSafety = null; _isLoadingSaran = false; }); return; }
    setState(() => _isLoadingSaran = true);
    try {
      final saran = await ProdukService.getSaranSafetyStok(kode);
      if (mounted) setState(() { _saranSafety = saran; _isLoadingSaran = false; });
    } catch (e) {
      if (mounted) setState(() { _saranSafety = null; _isLoadingSaran = false; });
    }
  }

  void _gunakanSaran(int nilai) => safetyController.text = nilai.toString();

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
              _buildField(label: 'Nama Produk', hint: 'Masukkan nama barang', controller: namaController, onChanged: _onNamaChanged),
              _buildField(label: 'Harga Jual', hint: 'Masukkan harga jual', isNumber: true, controller: hargaController, prefix: 'Rp '),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(label: 'Stok', hint: 'Masukkan stok', isNumber: true, controller: stokController),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(label: 'Safety Stok', hint: 'Masukkan safety stok', isNumber: true, controller: safetyController),
                        const SizedBox(height: 6),
                        _buildSaranWidget(),
                      ],
                    ),
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

  Widget _buildSaranWidget() {
    if (_isLoadingSaran) {
      return const Row(
        children: [
          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
          SizedBox(width: 6),
          Text('Memuat saran...', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      );
    }
    if (_saranSafety != null) {
      final saran = _saranSafety!['safety_stock_saran'] as int? ?? 0;
      if (saran > 0) {
        return GestureDetector(
          onTap: () => _gunakanSaran(saran),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD4A017)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFFB8860B)),
                const SizedBox(width: 4),
                Text('Saran: $saran unit', style: const TextStyle(fontSize: 12, color: Color(0xFF8B6914), fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('Gunakan', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        );
      }
    }
    if (namaController.text.trim().isEmpty) {
      return Text('Ketuk Nama Produk untuk melihat saran', style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic));
    }
    return Text('Tidak ada saran tersedia', style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic));
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    String? prefix,
    void Function(String)? onChanged,
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
            onChanged: onChanged,
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