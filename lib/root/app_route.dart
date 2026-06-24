import 'package:flutter/material.dart';
import '../global_widget/sidebar.dart';

//login
import '../screens/login_screen.dart';

//user
import '../screens/user_screen.dart';

//modul stok
import '../screens/modul_stok/produk_screen.dart';
// import '../screens/modul_stok/kartu_stok.dart'; // Import halaman Kartu Stok yang sudah dibuat
import '../screens/modul_stok/detail_kartu_stok.dart'; // Import halaman Detail Kartu Stok yang sudah dibuat
import '../screens/modul_stok/stok_opname_screen.dart'; // Import halaman Stok Opname yang sudah dibuat
import '../screens/modul_stok/input_stok_opname_screen.dart';
import '../screens/modul_stok/detail_stok_opname_screen.dart';
// import '../screens/modul_stok/edit_stok_opname_screen.dart';
import '../screens/modul_stok/laporan_stok.dart'; // Import halaman Laporan Stok yang sudah dibuat

//modul pembelian
import '../screens/modul_pembelian/supplier_screen.dart';
import '../screens/modul_pembelian/laporan_pembelian.dart';
import '../screens/modul_pembelian/pembelian_screen.dart';
import '../screens/modul_pembelian/input_pembelian_screen.dart'; // Import form input penerimaan
import '../screens/modul_pembelian/edit_pembelian_screen.dart'; // Import form edit penerimaan
import '../screens/modul_pembelian/detail_pembelian_screen.dart'; // Import form detail
import '../screens/modul_pembelian/input_penerimaan_screen.dart';
import '../screens/modul_pembelian/penerimaan_screen.dart'; // Import halaman Penerimaan Barang yang sudah dibuat
import '../screens/modul_pembelian/detail_penerimaan_screen.dart';

//modul pemjualan
import '../screens/modul_penjualan/customer_screen.dart';
import '../screens/modul_penjualan/transaksi_screen.dart';
import '../screens/modul_penjualan/laporan_penjualan.dart';
import '../screens/modul_penjualan/input_transaksi_screen.dart'; // Import halaman Input Transaksi yang sudah dibuat
import '../screens/modul_penjualan/view_transaksi_screen.dart'; // Import halaman Detail Transaksi yang sudah dibuat
import '../screens/modul_penjualan/edit_transaksi_screen.dart'; // Import halaman Edit Transaksi

//dashboard
import '../screens/dashboard/dashboard_screen.dart';

class AppRoute {
  // 1. Daftarkan nama-nama rute di sini agar tidak typo saat memanggilnya
  static const String login = '/login';
  static const String dashboard = '/';
  static const String user = '/user';

  //======== modul stok ========
  static const String produk = '/produk';
  //kartu stok
  // static const String kartuStok = '/kartu-stok';
  static const String detailKartuStok = '/detail-kartu-stok';// Nanti tinggal tambah: static 
  //stok opname
  static const String stokOpname = '/stok-opname';
  static const String inputStokOpname = '/input-stok-opname';
  static const String detailStokOpname = '/detail-stok-opname';
  // static const String editStokOpname = '/edit-stok-opname';
  //laporan
  static const String laporanStok = '/laporan-stok';

  //======== modul pembelian ========
  //supplier
  static const String supplier = '/supplier';
  //pembelian
  static const String pembelian = '/pembelian';
  static const String inputPembelian = '/input-pembelian';
  static const String editPembelian = '/edit-pembelian';  
  static const String detailPembelian = '/detail-pembelian';
  //laporan
  //penerimaan
  static const String penerimaan = '/penerimaan';
  static const String laporanPembelian = '/laporan-pembelian';
  static const String inputPenerimaan = '/input-penerimaan';
  static const String detailPenerimaan = '/detail-penerimaan';  

  //======== modul pemjualan ========
 static const String customer = '/customer';
  static const String transaksi = '/transaksi';
  static const String inputTransaksi = '/input-transaksi';
  static const String detailTransaksi = '/detail-transaksi';
  static const String editTransaksi = '/edit-transaksi';
  static const String laporanPenjualan = '/laporan-penjualan';

  // 2. Fungsi pembungkus (Wrapper) agar Sidebar tidak perlu ditulis berulang kali
  static Widget _withSidebar(Widget page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jika lebar layar kurang dari 768px, gunakan Drawer (overlay)
        if (constraints.maxWidth < 768) {
          return Scaffold(
            drawer: Drawer(child: Sidebar(isDrawer: true)),
            body: page,
          );
        } else {
          // Jika lebar layar cukup, tampilkan dengan sidebar inline
          return Scaffold(
            body: Row(
              children: [
                const Sidebar(), // Sidebar akan otomatis nempel di sebelah kiri
                Expanded(child: page), // Konten halaman di sebelah kanan
              ],
            ),
          );
        }
      },
    );
  }

  // 3. Generator Rute dengan transisi instan
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;

    // Tentukan rute yang dipanggil akan membuka halaman apa
    switch (settings.name) {
      case dashboard:
        page = _withSidebar(const DashboardScreen());
        break;

      case login:
        page = const LoginScreen(); // Langsung return screen-nya tanpa sidebar
        break;  
 
      case user:
        page = _withSidebar(const UserScreen());
        break;

      //======== modul stok ========  
      case produk:
        page = _withSidebar(const ProdukScreen());
        break;
      //kartu stok  
      // case kartuStok:
      //   page = _withSidebar(const KartuStokScreen());
      //   break;
      case detailKartuStok:
        page = _withSidebar(const DetailKartuStokScreen());
        break; 
      //stok opname    
      case stokOpname:
        page = _withSidebar(const StokOpnameScreen());
        break;
      case inputStokOpname:
        page = _withSidebar(const InputStokOpnameScreen());
        break;  
      case detailStokOpname:
        page = _withSidebar(const DetailStokOpnameScreen());
        break;
      // case editStokOpname:
      //   page = _withSidebar(const EditStokOpnameScreen());
      //   break;    
      //laporan  
      case laporanStok:
        page = _withSidebar(const LaporanStokScreen());
        break;

      //======== modul pembelian ========  
      //supplier    
      case supplier:
        page = _withSidebar(const SupplierScreen());
        break;
      //pembelian
      case pembelian:
        page = _withSidebar(const PembelianScreen());
        break;
      case inputPembelian:
        page = _withSidebar(const InputPembelianScreen());
        break;
      case editPembelian:
        page = _withSidebar(const EditPembelianScreen());
        break;
      case detailPembelian:
        page = _withSidebar(const DetailPembelianScreen());
          break;
      //penerimaan
      case penerimaan:
        page = _withSidebar(PenerimaanScreen());
        break;
      case inputPenerimaan:
        page = _withSidebar(const InputPenerimaanScreen());
        break;  
      case detailPenerimaan:
        page = _withSidebar(const DetailPenerimaanScreen());   
        break;     
      //laporan
      // case laporanPembelian:
      //   page = _withSidebar(const LaporanPembelianScreen());
      //   break;  

      //======== modul pemjualan ========
      //customer
      case customer:
        page = _withSidebar(const CustomerScreen());
        break;
      //transaksi
      case transaksi:
        page = _withSidebar(const TransaksiScreen());
        break;
      case inputTransaksi:
        page = _withSidebar(const InputTransaksiScreen()); 
        break;
      case detailTransaksi:
        final args = settings.arguments as Map<String, dynamic>?;
        page = _withSidebar(ViewTransaksiScreen(penjualanData: args)); 
        break;
      case editTransaksi:
        page = _withSidebar(const EditTransaksiScreen());
        break;     
      //laporan 
      // case laporanPenjualan:
      //   page = _withSidebar(const LaporanPenjualanScreen());
      //   break;
      
      default:
        page = _withSidebar(
          const Center(child: Text('Halaman tidak ditemukan')),
        );
    }

    // Return PageRouteBuilder agar transisinya instan (Duration.zero)
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      settings: settings, // Penting agar nama rute tercatat di sistem Flutter
    );
  }
}