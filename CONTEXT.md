# Toko Angel

A store management system for Toko Angel — supporting admin and karyawan roles for managing inventory, purchasing, sales, and stock operations.

## Language

**Toko Angel**:
A retail store. The application is an internal management system used by its admin and karyawan staff.
_Avoid_: Toko Angel app (redundant)

**Brand Personality**:
Modern & profesional. Warna dark slate sebagai primary dengan aksen gold/amber.

**Laba Kotor**:
Total pendapatan penjualan (penjualan.total_harga) tanpa dikurangi biaya apapun.

**Pengeluaran**:
Total biaya pembelian barang dari supplier (pembelian.total_harga).

**Laba Bersih**:
Laba Kotor dikurangi Pengeluaran.

**Barang Menipis**:
Produk dengan stok > 0 yang berada di atau di bawah reorder point (ROP).

**Barang Habis**:
Produk dengan stok = 0.

**Dashboard Periode**:
Rentang tanggal (start_date, end_date) yang memfilter semua metrik dashboard. Default: bulan berjalan (tanggal 1 sampai hari ini).
