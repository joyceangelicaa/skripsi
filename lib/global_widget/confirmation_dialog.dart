import 'package:flutter/material.dart';

class ConfirmationDialog extends StatefulWidget {
  final bool isSuccess; // Penentu tema (Sukses = Hijau, Gagal = Merah)
  final String title;
  final String message;

  const ConfirmationDialog({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  void initState() {
    super.initState();
    
    // --- TIMER OTOMATIS TUTUP ---
    // Pop-up akan otomatis memanggil fungsi pop (tutup) setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(30.0), // Padding yang luas agar lega
        child: Column(
          mainAxisSize: MainAxisSize.min, // Agar tinggi pop-up menyesuaikan isi
          children: [
            // 1. IKON ANIMATIF/BESAR
            Icon(
              widget.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: widget.isSuccess ? Colors.green : Colors.red,
              size: 80,
            ),
            
            const SizedBox(height: 20),
            
            // 2. JUDUL
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),
            
            // 3. PESAN DETAIL
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Perhatikan: Tombol aksi sudah tidak ada lagi di sini!
          ],
        ),
      ),
    );
  }
}