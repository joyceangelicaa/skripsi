import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/produk_service.dart';
class FormEditProduk extends StatefulWidget {
  final String kodeAwal;
  final String namaAwal;
  final String hargaAwal;
  final String stokAwal;
  final String safetyStokAwal;
  const FormEditProduk({
    super.key,
    required this.kodeAwal,
    required this.namaAwal,
    required this.hargaAwal,
    required this.stokAwal,
    required this.safetyStokAwal,
  });
  @override
  State<FormEditProduk> createState() => _FormEditProdukState();
}
class _FormEditProdukState extends State<FormEditProduk> {
  late TextEditingController kode;
  late TextEditingController nama;
  late TextEditingController harga;
  // late TextEditingController stok;
  late TextEditingController safety;
  bool isLoading = false;

  Map<String, dynamic>? _saranSafety;
  bool _isLoadingSaran = false;

  Future<void> _fetchSaranSafety() async {
    setState(() => _isLoadingSaran = true);
    try {
      final saran = await ProdukService.getSaranSafetyStok(widget.kodeAwal);
      if (mounted) setState(() { _saranSafety = saran; _isLoadingSaran = false; });
    } catch (e) {
      if (mounted) setState(() { _saranSafety = null; _isLoadingSaran = false; });
    }
  }

  void _gunakanSaran(int nilai) => safety.text = nilai.toString();

  @override
  void initState() {
    super.initState();
    kode = TextEditingController(text: widget.kodeAwal);
    nama = TextEditingController(text: widget.namaAwal);
    harga = TextEditingController(text: widget.hargaAwal);
    // stok = TextEditingController(text: widget.stokAwal);
    safety = TextEditingController(text: widget.safetyStokAwal);
    _fetchSaranSafety();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.edit_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Edit Produk',
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
              _buildField(label: 'Kode Produk', controller: kode),
              _buildField(label: 'Nama Produk', controller: nama),
              _buildField(label: 'Harga Jual', controller: harga, isNumber: true, prefix: 'Rp '),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildReadOnlyField(label: 'Stok', value: widget.stokAwal),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(label: 'Safety Stok', controller: safety, isNumber: true),
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
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (kode.text.isEmpty ||
                      nama.text.isEmpty ||
                      harga.text.isEmpty ||
                      safety.text.isEmpty) {
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
                  setState(() => isLoading = true);
                  try {
                    final hargaVal = double.tryParse(harga.text);
                    final safetyVal = int.tryParse(safety.text);
                    if (hargaVal == null || safetyVal == null) {
                      showDialog(
                        context: context,
                        builder: (context) => const ConfirmationDialog(
                          isSuccess: false,
                          title: 'Format Salah',
                          message: 'Harga dan Safety Stok harus berupa angka.',
                        ),
                      );
                      setState(() => isLoading = false);
                      return;
                    }
                    await ProdukService.editProduk({
                      "kode_produk": kode.text,
                      "nama_produk": nama.text,
                      "harga_jual": hargaVal,
                      "safety_stock": safetyVal,
                    });
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const ConfirmationDialog(
                        isSuccess: true,
                        title: 'Berhasil',
                        message: 'Data berhasil diupdate',
                      ),
                    );
                  } catch (e) {
                    setState(() => isLoading = false);
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        isSuccess: false,
                        title: 'Gagal',
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
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Perubahan'),
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
    return Text('Tidak ada saran tersedia', style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic));
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
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
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildField({
    required String label,
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