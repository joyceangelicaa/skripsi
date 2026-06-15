import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart'; // <-- Import baru ditambahkan
import '../../global_widget/app_bar.dart';
import '../../global_widget/table.dart';
import '../../service/laporan_stok_service.dart';
import '../../service/laporan_stok_pdf_service.dart';

class LaporanStokScreen extends StatefulWidget {
  const LaporanStokScreen({super.key});

  @override
  State<LaporanStokScreen> createState() => _LaporanStokScreenState();
}

class _LaporanStokScreenState extends State<LaporanStokScreen> {
  final GlobalKey _filterButtonKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  DateTime? _startDate;
  DateTime? _endDate;

  bool isLoading = false;
  List<dynamic> items = [];
  List<dynamic> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final res = await LaporanStokService.getLaporanStok(
        startDate: _startDate?.toIso8601String().substring(0, 10),
        endDate: _endDate?.toIso8601String().substring(0, 10),
        limit: 999,
      );

      setState(() {
        items = res['items'];
        _filteredItems = List.from(res['items']);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat laporan: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isLoading = false);
  }

  void _closeDatePickerPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDatePickerPopup() {
    if (_overlayEntry != null) {
      _closeDatePickerPopup();
      return;
    }

    DateTime tempStart = _startDate ?? DateTime.now();
    DateTime tempEnd = _endDate ?? DateTime.now();

    final renderBox = _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDatePickerPopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            left: offset.dx,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 340, // Lebar disesuaikan agar pas dengan 1 kalender
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    
                    // --- UI KALENDER YANG BARU ---
                    SizedBox(
                      height: 280, // Tinggi kalender
                      child: SfDateRangePicker(
                        selectionMode: DateRangePickerSelectionMode.range, // Mode range otomatis
                        initialSelectedRange: PickerDateRange(tempStart, tempEnd),
                        // Warna dasar kalender disesuaikan dengan tema gelap kamu
                        selectionColor: const Color(0xFF1E293B),
                        startRangeSelectionColor: const Color(0xFF1E293B),
                        endRangeSelectionColor: const Color(0xFF1E293B),
                        rangeSelectionColor: const Color(0xFF1E293B).withOpacity(0.1),
                        todayHighlightColor: const Color(0xFF1E293B),
                        onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                          if (args.value is PickerDateRange) {
                            tempStart = args.value.startDate ?? tempStart;
                            // Jika user baru klik 1 tanggal (belum milih tanggal akhir), 
                            // otomatis tanggal akhir disamakan dengan tanggal mulai
                            tempEnd = args.value.endDate ?? args.value.startDate ?? tempEnd;
                          }
                        },
                      ),
                    ),
                    // --------------------------------
                    
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _closeDatePickerPopup,
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _startDate = tempStart;
                              _endDate = tempEnd;
                            });
                            _closeDatePickerPopup();
                            fetchData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  String _getButtonLabel() {
    if (_startDate == null || _endDate == null) return 'Filter Periode';
    return '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(items);
      } else {
        _filteredItems = items.where((item) {
          return item.values.any((value) {
            return value.toString().toLowerCase().contains(query.toLowerCase());
          });
        }).toList();
      }
      _sortData();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortData();
    });
  }

  void _sortData() {
    if (_sortColumnIndex == null) return;
    final ci = _sortColumnIndex!;
    final asc = _sortAscending;
    _filteredItems.sort((a, b) {
      int result;
      switch (ci) {
        case 1:
          result = (a['nama_produk'] ?? '').toString().compareTo(
              (b['nama_produk'] ?? '').toString());
          break;
        case 2:
          result = ((a['stok_awal'] ?? 0) as num)
              .compareTo((b['stok_awal'] ?? 0) as num);
          break;
        case 3:
          result = ((a['stok_masuk'] ?? 0) as num)
              .compareTo((b['stok_masuk'] ?? 0) as num);
          break;
        case 4:
          result = ((a['stok_keluar'] ?? 0) as num)
              .compareTo((b['stok_keluar'] ?? 0) as num);
          break;
        case 5:
          result = ((a['stok_akhir'] ?? 0) as num)
              .compareTo((b['stok_akhir'] ?? 0) as num);
          break;
        default:
          return 0;
      }
      return asc ? result : -result;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalAppBar(title: 'Laporan Stok'),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1000;
                final row = Row(
                children: [
              ElevatedButton.icon(
                key: _filterButtonKey,
                onPressed: _showDatePickerPopup,
                icon: const Icon(Icons.calendar_month, size: 20),
                label: Text(_getButtonLabel()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              isDesktop
                  ? Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterList,
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 250,
                      height: 50,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterList,
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final pdfBytes = await LaporanStokPdfService.generateLaporanStokPdf(
                      items: _filteredItems,
                      startDate: _startDate,
                      endDate: _endDate,
                    );
                    final filename = _startDate != null && _endDate != null
                        ? 'laporan_stok_${LaporanStokPdfService.formatDate(_startDate)}_${LaporanStokPdfService.formatDate(_endDate)}.pdf'
                        : 'laporan_stok.pdf';
                    LaporanStokPdfService.downloadPdf(pdfBytes, filename);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal cetak: ${e.toString().replaceAll("Exception: ", "")}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.print, size: 20),
                label: const Text("Cetak Laporan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ],
            );
            return isDesktop ? row : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            );
          },
          ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GlobalDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text('No')),
                      DataColumn(label: const Text('Nama Barang'), onSort: _onSort),
                      DataColumn(label: const Text('Stok Awal'), onSort: _onSort),
                      DataColumn(label: const Text('Masuk'), onSort: _onSort),
                      DataColumn(label: const Text('Keluar'), onSort: _onSort),
                      DataColumn(label: const Text('Stok Akhir'), onSort: _onSort),
                    ],
                    rows: List.generate(_filteredItems.length, (index) {
                      final item = _filteredItems[index];

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(item['nama_produk'] ?? '-')),
                          DataCell(Text('${item['stok_awal']}')),
                          DataCell(Text(
                            '${item['stok_masuk']}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            '${item['stok_keluar']}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            '${item['stok_akhir']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          )),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}