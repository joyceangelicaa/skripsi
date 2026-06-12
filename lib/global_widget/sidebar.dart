import 'package:flutter/material.dart';
// import '../screens/produk_screen.dart';
import '../root/app_route.dart';
import 'confirmation_dialog.dart';
import '../service/user_service.dart';

class Sidebar extends StatefulWidget {
  final bool isDrawer;
  static final ValueNotifier<bool> isExpandedNotifier = ValueNotifier(true); // Notifier untuk status sidebar expand/collapse
  const Sidebar({super.key, this.isDrawer = false});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final bool _isDrawer;

  @override
  void initState() {
    super.initState();
    _isDrawer = widget.isDrawer;
    Sidebar.isExpandedNotifier.addListener(_onExpandedChanged);
  }

  @override
  void dispose() {
    Sidebar.isExpandedNotifier.removeListener(_onExpandedChanged);
    super.dispose();
  }

  void _onExpandedChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final role = UserService.role;

    // Jika mode drawer, tampilkan full tanpa toggle collapse
    if (_isDrawer) {
      return _buildDrawerContent();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Lebar menyesuaikan state: 250 jika terbuka, 70 jika tertutup
      width: Sidebar.isExpandedNotifier.value ? 250 : 70,
      color: const Color(0xFF1E293B), // Warna biru gelap profesional
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Spasi atas (Safe Area)
          
          // Bagian Header & Ikon Garis Tiga (Hamburger)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: Sidebar.isExpandedNotifier.value 
                  ? MainAxisAlignment.spaceBetween 
                  : MainAxisAlignment.center,
              children: [
                if (Sidebar.isExpandedNotifier.value)
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(
                      'Menu Utama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // IconButton(
                //   icon: const Icon(Icons.menu, color: Colors.white),
                //   onPressed: () {
                //     setState(() {
                //       isExpanded = !isExpanded; // Mengubah state buka/tutup
                //     });
                //   },
                // ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, thickness: 1, height: 30),

          // Menu Items yang sudah diisikan
          Expanded(
            child: ListView(
              children: [
                // --- TAMBAHAN BARU: MENU DASHBOARD ---
                if (role == 'admin')
                _buildSingleMenu(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                  },
                ),

                // --- TAMBAHAN BARU: MENU USER ---
                if (role == 'admin')
                _buildSingleMenu(
                  icon: Icons.person_outline,
                  title: 'User',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoute.user);
                  },
                ),

                // --- MODUL STOK ---
                _buildModuleMenu(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stok',
                  subMenus: [
                    if (role == 'admin')
                    _buildSubMenu(title: 'Produk', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.produk);
                    }),
                    // _buildSubMenu(title: 'Kartu Stok', onTap: () {
                    //   Navigator.pushReplacementNamed(context, AppRoute.kartuStok);
                    // }),
                    // _buildSubMenu(title: 'Daftar Reorder', onTap: () {}),
                    _buildSubMenu(title: 'Stock Opname', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.stokOpname);
                    }),
                    if (role == 'admin')
                    _buildSubMenu(title: 'Laporan Stok', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.laporanStok);
                    }),
                  ],
                ),

                // --- MODUL PEMBELIAN ---
                if (role == 'admin')
                _buildModuleMenu(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Pembelian',
                  subMenus: [
                    _buildSubMenu(title: 'Pembelian Barang', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
                    }),
                    _buildSubMenu(title: 'Penerimaan Barang', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.penerimaan);
                    }),
                    // _buildSubMenu(title: 'Produk', onTap: () {}),
                    _buildSubMenu(title: 'Supplier', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.supplier);
                    }),
                    _buildSubMenu(title: 'Laporan Pembelian', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.laporanPembelian);
                    }),
                    // _buildSubMenu(title: 'Kartu Stok', onTap: () {}),
                  ],
                ),

                // --- MODUL PENJUALAN ---
                if (role == 'admin')
                _buildModuleMenu(
                  icon: Icons.point_of_sale_outlined,
                  title: 'Penjualan',
                  subMenus: [
                    _buildSubMenu(title: 'Transaksi', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.transaksi);
                    }),
                    _buildSubMenu(title: 'Customer', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.customer);
                    }),
                    // _buildSubMenu(title: 'Kartu Stok', onTap: () {}),
                    // _buildSubMenu(title: 'Produk', onTap: () {}),
                    _buildSubMenu(title: 'Laporan Penjualan', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.laporanPenjualan);
                    }),
                  ],
                ),
              ],
            ),
          ),
          
          // --- TOMBOL LOGOUT ---
          const Divider(color: Colors.white24, thickness: 1, height: 1), 
          _buildSingleMenu(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: () async {
              await UserService.clearToken();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoute.login, (route) => false);
            },
          ),
          const SizedBox(height: 20), // Spasi bawah agar tidak terlalu menempel ke tepi layar
        ],
      ),
    );
  }

  // Helper baru untuk Modul Utama (Berupa Dropdown)
  Widget _buildModuleMenu({
    required IconData icon,
    required String title,
    required List<Widget> subMenus,
  }) {
    // Jika sidebar ditutup (kecil) dan bukan mode drawer, hanya tampilkan ikonnya saja
    if (!Sidebar.isExpandedNotifier.value && !_isDrawer) {
      return InkWell(
        onTap: () {
          Sidebar.isExpandedNotifier.value = true; // Otomatis membuka sidebar jika ikon diklik
        },
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
    }

    // Jika sidebar terbuka, tampilkan dropdown (ExpansionTile)
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white, size: 24),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        children: subMenus, // Memasukkan sub-menu di sini
      ),
    );
  }

  // Helper baru untuk Sub-menu di dalam Modul
  Widget _buildSubMenu({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.only(
            left: 55.0, top: 12.0, bottom: 12.0, right: 20.0), // Indentasi agar menjorok ke dalam
        child: Row(
          children: [
            const Icon(Icons.circle, color: Colors.white54, size: 8), // Ikon titik kecil
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper untuk menu tunggal (yang tidak punya dropdown seperti Dashboard, User, dan Logout) ---
  Widget _buildSingleMenu({required IconData icon, required String title, required VoidCallback onTap}) {
    // Jika sidebar ditutup dan bukan mode drawer, tampilkan ikonnya saja di tengah
    if (!Sidebar.isExpandedNotifier.value && !_isDrawer) {
      return InkWell(
        onTap: onTap, // Tetap berfungsi navigasi meskipun sidebar sedang mengecil
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
    }

    // Jika sidebar terbuka, sejajarkan tampilannya dengan menu lain
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Method khusus untuk mode Drawer (HP) ---
  Widget _buildDrawerContent() {
    final role = UserService.role;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E293B), // Warna biru gelap profesional
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // Spasi atas (Safe Area)

          // Header
          const Center(
            child: Text(
              'Menu Utama',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(color: Colors.white24, thickness: 1, height: 30),

          // Menu Items
          Expanded(
            child: ListView(
              children: [
                // --- MENU DASHBOARD ---
                if (role == 'admin')
                _buildSingleMenu(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                  },
                ),

                // --- MENU USER ---
                if (role == 'admin')
                _buildSingleMenu(
                  icon: Icons.person_outline,
                  title: 'User',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoute.user);
                  },
                ),

                // --- MODUL STOK ---
                _buildModuleMenu(
                  icon: Icons.inventory_2_outlined,
                  title: 'Modul Stok',
                  subMenus: [
                    if (role == 'admin')
                    _buildSubMenu(title: 'Produk', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.produk);
                    }),
                    _buildSubMenu(title: 'Stock Opname', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.stokOpname);
                    }),
                    if (role == 'admin')
                    _buildSubMenu(title: 'Laporan', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.laporanStok);
                    }),
                  ],
                ),

                // --- MODUL PEMBELIAN ---
                if (role == 'admin')
                _buildModuleMenu(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Modul Pembelian',
                  subMenus: [
                    _buildSubMenu(title: 'Pembelian Barang', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.pembelian);
                    }),
                    _buildSubMenu(title: 'Penerimaan Barang', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.penerimaan);
                    }),
                    _buildSubMenu(title: 'Supplier', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.supplier);
                    }),
                    _buildSubMenu(title: 'Laporan', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.laporanPembelian);
                    }),
                  ],
                ),

                // --- MODUL PENJUALAN ---
                if (role == 'admin')
                _buildModuleMenu(
                  icon: Icons.point_of_sale_outlined,
                  title: 'Modul Penjualan',
                  subMenus: [
                    _buildSubMenu(title: 'Transaksi', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.transaksi);
                    }),
                    _buildSubMenu(title: 'Customer', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.customer);
                    }),
                    _buildSubMenu(title: 'Laporan', onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoute.laporanPenjualan);
                    }),
                  ],
                ),
              ],
            ),
          ),

          // --- TOMBOL LOGOUT ---
          const Divider(color: Colors.white24, thickness: 1, height: 1),
          _buildSingleMenu(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: () async {
              await UserService.clearToken();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoute.login, (route) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}