import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../global_widget/app_bar.dart';
import '../../service/dashboard_service.dart';
import '../../service/reorder_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  double _pendapatan = 0;
  double _pengeluaran = 0;
  double get _labaBersih => _pendapatan - _pengeluaran;
  List<Map<String, dynamic>> _produkTerlaris = [];
  int _pembelianBaru = 0;
  int _pembelianProses = 0;
  int _pembelianSelesai = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _barangMenipis = [];
  List<Map<String, dynamic>> _barangHabis = [];
  List<Map<String, dynamic>> _barangOverstock = []; 

  // final List<Map<String, dynamic>> dummyBarangMenipis = [
  //   {'nama': 'Beras 5kg', 'qty': 5, 'rop': 10},
  //   {'nama': 'Gula Pasir 1kg', 'qty': 3, 'rop': 8},
  //   {'nama': 'Minyak Goreng 2L', 'qty': 2, 'rop': 5},
  //   {'nama': 'Telur 1kg', 'qty': 4, 'rop': 6},
  //   {'nama': 'Kopi Bubuk 200g', 'qty': 1, 'rop': 3},
  // ];

  // final List<Map<String, dynamic>> dummyBarangHabis = [
  //   {'nama': 'Susu Kental Manis', 'qty': 0, 'rop': 10},
  //   {'nama': 'Mie Instan Goreng', 'qty': 0, 'rop': 20},
  //   {'nama': 'Saos Tomat', 'qty': 0, 'rop': 5},
  //   {'nama': 'Kecap Manis', 'qty': 0, 'rop': 8},
  // ];

  List<double> _penjualanHarian = [];
  List<String> _tanggalPenjualan = [];

  String _formatCurrency(double amount) {
    String raw = amount.toInt().toString();
    String result = '';
    int count = 0;
    for (int i = raw.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = '.$result';
      result = '${raw[i]}$result';
      count++;
    }
    return 'Rp $result';
  }

  String _formatDate(DateTime d) {
    return '${d.day} ${_monthName(d.month)} ${d.year}';
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[m - 1];
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _fetchData();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await ReorderService.hitungSemua();

      final results = await Future.wait([
        DashboardService.getPendapatan(startDate: _startDate, endDate: _endDate),
        DashboardService.getPengeluaran(startDate: _startDate, endDate: _endDate),
        DashboardService.getStatusPembelian(startDate: _startDate, endDate: _endDate),
        DashboardService.getProdukTerlaris(startDate: _startDate, endDate: _endDate),
        DashboardService.getPenjualanHarian(startDate: _startDate, endDate: _endDate),
        DashboardService.getProdukOverstock(),
      ]);

      // 3. Ambil rekomendasi & pisahkan Menipis vs Habis
      final rekomendasi = await ReorderService.getRekomendasi(limit: 999, offset: 0);
      final items = rekomendasi['items'] as List<dynamic>;
      final menipis = <Map<String, dynamic>>[];
      final habis = <Map<String, dynamic>>[];
      for (var item in items) {
        if (item['stok_produk'] == 0) {
          habis.add(item as Map<String, dynamic>);
        } else {
          menipis.add(item as Map<String, dynamic>);
        }
      }

      setState(() {
        _pendapatan = results[0] as double;
        _pengeluaran = results[1] as double;
        final status = results[2] as Map<String, int>;
        _pembelianBaru = status['baru']!;
        _pembelianProses = status['proses']!;
        _pembelianSelesai = status['selesai']!;
        _produkTerlaris = (results[3] as List<Map<String, dynamic>>)
            .map((e) => {
              'nama': e['nama_produk'] as String,
              'total': e['jumlah_terjual'] as int,
            })
            .toList();
        final harian = results[4] as List<Map<String, dynamic>>;
        _penjualanHarian = harian
            .map<double>((e) => (e['total_penjualan'] as num).toDouble())
            .toList();
        _tanggalPenjualan = harian
            .map<String>((e) => e['tanggal'] as String)
            .toList();
        _barangMenipis = menipis;
        _barangHabis = habis; 
        _barangOverstock = results[5] as List<Map<String, dynamic>>;   
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Dashboard'),
          const SizedBox(height: 24),
          _buildDateFilter(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatCards(),
                        const SizedBox(height: 24),
                        _buildRopLists(),
                        const SizedBox(height: 24),
                        _buildOverstockCard(),   
                        const SizedBox(height: 24),
                        _buildLineChartCard(),
                        const SizedBox(height: 24),
                        _buildChartRow(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        _buildDatePicker(
          label: 'Tanggal Awal',
          date: _startDate,
          onTap: _pickStartDate,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
        ),
        _buildDatePicker(
          label: 'Tanggal Akhir',
          date: _endDate,
          onTap: _pickEndDate,
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: const Color(0xFF1E293B)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        _buildStatCard(
          title: 'Pendapatan',
          amount: _pendapatan,
          icon: Icons.trending_up,
          color: const Color(0xFFD4A017),
          lightColor: const Color(0xFFFFF8E1),
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          title: 'Pengeluaran',
          amount: _pengeluaran,
          icon: Icons.shopping_cart_outlined,
          color: const Color(0xFFEF4444),
          lightColor: const Color(0xFFFFE4E6),
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          title: 'Laba Bersih',
          amount: _labaBersih,
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF22C55E),
          lightColor: const Color(0xFFDCFCE7),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color lightColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRopLists() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRopListCard('Barang Menipis', _barangMenipis, const Color(0xFFF59E0B))),
        const SizedBox(width: 20),
        Expanded(child: _buildRopListCard('Barang Habis', _barangHabis, const Color(0xFFEF4444), showStok: true)),
      ],
    );
  }

  Widget _buildOverstockCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Produk Overstock',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_barangOverstock.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4A017),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tableHeader('Nama Barang', flex: 3),
                _tableHeader('Kode Batch', flex: 2),
                _tableHeader('Sisa Stok', flex: 1),
              ],
            ),
          ),
          if (_barangOverstock.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Tidak ada data',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _barangOverstock.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final item = _barangOverstock[i];
                  final produk = item['produk'] as Map<String, dynamic>? ?? {};
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            (produk['nama_produk'] as String?) ?? '-',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            (item['kode_batch'] as String?) ?? '-',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item['sisa_stok'] ?? 0}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD4A017),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRopListCard(String title, List<Map<String, dynamic>> items, Color accentColor, {bool showStok = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tableHeader('Nama Barang', flex: showStok ? 3 : 4),
                if (showStok) _tableHeader('Stok', flex: 1),
                _tableHeader('ROP', flex: 1),
              ],
            ),
          ),
          if (items.isEmpty)
            const SizedBox(
              height: 260,
              child: Center(
                child: Text(
                  'Tidak ada data',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: showStok ? 3 : 4,
                          child: Text(
                            item['nama_produk'] as String,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        if (showStok)
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item['stok_produk']}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: item['stok_produk'] == 0 ? const Color(0xFFEF4444) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item['reorder_point']}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLineChartCard() {
    final maxVal = _penjualanHarian.isEmpty
        ? 18000000.0
        : _penjualanHarian.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxVal == 0 ? 18000000.0 : maxVal * 1.2;
    final interval = chartMaxY > 5000000 ? 2500000.0 : 1000000.0;
    final bottomInterval = _penjualanHarian.length > 20 ? 5 : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 20, color: const Color(0xFF1E293B)),
              const SizedBox(width: 8),
              const Text(
                'Penjualan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: _penjualanHarian.isEmpty
                ? const Center(child: Text('Tidak ada data penjualan'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: interval,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 100,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              if (value % interval != 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  _formatCurrency(value),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: bottomInterval.toDouble(),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _tanggalPenjualan.length) return const SizedBox.shrink();
                              final parts = _tanggalPenjualan[idx].split('-');
                              final label = '${parts[2]}/${parts[1]}';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: chartMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            _penjualanHarian.length,
                            (i) => FlSpot(i.toDouble(), _penjualanHarian[i]),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: const Color(0xFFD4A017),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: _penjualanHarian.length <= 15,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFD4A017).withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildProdukTerlarisBarChart()),
        const SizedBox(width: 20),
        Expanded(child: _buildDonutChartCard()),
      ],
    );
  }

  Widget _buildProdukTerlarisBarChart() {
    final colors = [
      const Color(0xFFD4A017),
      const Color(0xFF3B82F6),
      const Color(0xFF22C55E),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
    ];

    final maxTotal = _produkTerlaris.isEmpty
        ? 1
        : _produkTerlaris
            .map<int>((e) => e['total'] as int)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: const Color(0xFF1E293B)),
              const SizedBox(width: 8),
              const Text(
                'Produk Terlaris',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_produkTerlaris.length, (i) {
            final item = _produkTerlaris[i];
            final pct = (item['total'] as int) / maxTotal;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      item['nama'] as String,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: colors[i % colors.length],
                        minHeight: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${item['total']}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDonutChartCard() {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
    ];

    final statusData = [
      {'status': 'Baru', 'count': _pembelianBaru},
      {'status': 'Proses', 'count': _pembelianProses},
      {'status': 'Selesai', 'count': _pembelianSelesai},
    ];

    double total = statusData.fold<double>(0, (sum, item) => sum + (item['count'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_large, size: 20, color: const Color(0xFF1E293B)),
              const SizedBox(width: 8),
              const Text(
                'Status Pembelian',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 45,
                      sections: List.generate(statusData.length, (i) {
                        final pct = total > 0 ? (statusData[i]['count'] as int) / total : 0;
                        return PieChartSectionData(
                          color: colors[i % colors.length],
                          value: pct * 100,
                          title: total > 0 ? '${(pct * 100).toStringAsFixed(0)}%' : '0%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(statusData.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusData[i]['status'] as String,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${statusData[i]['count']})',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors[i % colors.length],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
