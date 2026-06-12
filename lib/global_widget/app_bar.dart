import 'package:flutter/material.dart';
import 'sidebar.dart';
import '../service/user_service.dart';

class GlobalAppBar extends StatelessWidget {
  final String title;

  const GlobalAppBar({
    super.key,
    required this.title,
  });

  // Fungsi untuk menampilkan pop-up dengan desain awal tapi posisi di bawah avatar
  Future<void> _showUserInformation(BuildContext context) async {
    await UserService.loadUserData();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nama = UserService.namaUser ?? '-';
        final email = UserService.email ?? '-';
        final role = UserService.role ?? '-';
        return AlertDialog(
          // --- KUNCI POSISI ---
          alignment: Alignment.topRight, // Memaksa pop-up ke kanan atas
          insetPadding: const EdgeInsets.only(top: 70, right: 16), // Jarak dari atas (70) agar pas di bawah avatar
          // --------------------
          
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.account_circle, color: Color(0xFF1E293B)),
              SizedBox(width: 8),
              Text(
                'Profil Pengguna',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 300, // Membatasi lebar maksimum pop-up
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF1E293B),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Nama', nama),
                _buildInfoRow('Email', email), 
                _buildInfoRow('Peran', role),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget pembantu untuk merapikan baris informasi di dalam pop-up
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 768;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                  onPressed: () {
                    if (isSmall) {
                      Scaffold.of(context).openDrawer();
                    } else {
                      Sidebar.isExpandedNotifier.value =
                          !Sidebar.isExpandedNotifier.value;
                    }
                  },
                ),
                // 1. Teks Judul
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),

                // Memakai Spacer untuk mendorong Avatar ke bagian paling kanan
                const Spacer(),

                // 3. Avatar Profil yang bisa diklik
                GestureDetector(
                  onTap: () => _showUserInformation(context),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF1E293B),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Jarak tipis dari ujung kanan layar
              ],
            ),
            
            const SizedBox(height: 12), // Jarak sedikit antara teks dan garis

            // 2. Garis Tipis dan Shadow
            Container(
              height: 1.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}