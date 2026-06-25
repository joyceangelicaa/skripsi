// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart'; // Tambahkan import ini
// import '../../global_widget/app_bar.dart';
// import '../../global_widget/table.dart';
// import '../../service/laporan_pembelian_service.dart';
// import '../../service/laporan_pembelian_pdf_service.dart';

// class LaporanPembelianScreen extends StatefulWidget {
//   const LaporanPembelianScreen({super.key});

//   @override
//   State<LaporanPembelianScreen> createState() => _LaporanPembelianScreenState();
// }

// class _LaporanPembelianScreenState extends State<LaporanPembelianScreen> {
//   // --- VARIABEL UNTUK DATE PICKER ---
//   final GlobalKey _filterButtonKey = GlobalKey();
//   OverlayEntry? _overlayEntry;
//   DateTime? _startDate;
//   DateTime? _endDate;
//   // ----------------------------------

//   // --- VARIABEL FILTER STATUS ---
//   String? _selectedStatus;
//   // ------------------------------

//   List<dynamic> items = [];
//   List<dynamic> _filteredItems = [];
//   bool isLoading = true;
//   final TextEditingController _searchController = TextEditingController();
//   int? _sortColumnIndex = 1;
//   bool _sortAscending = true;

//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }

//   Future<void> loadData() async {
//     // Tambahkan setState isLoading = true agar saat difilter ulang loadingnya muncul
//     setState(() => isLoading = true); 
    
//     try {
//       // Catatan: Logika aslimu tidak mengirim parameter tanggal.
//       // Jika nanti servicenya sudah disesuaikan untuk menerima parameter tanggal, 
//       // kamu bisa menambahkannya di sini (contoh: startDate: _startDate, dst).
//       final data = await LaporanPembelianService.getLaporanPembelian(
//         status: _selectedStatus,
//         startDate: _startDate?.toIso8601String(),
//         endDate: _endDate?.toIso8601String(),
//         limit: 999,
//       );

//       // Urutkan dari tanggal paling lama ke terbaru
//       data.sort((a, b) {
//         final tglA = DateTime.tryParse(a['tanggal_pembelian'] ?? '') ?? DateTime(2000);
//         final tglB = DateTime.tryParse(b['tanggal_pembelian'] ?? '') ?? DateTime(2000);
//         return tglA.compareTo(tglB);
//       });

//       setState(() {
//         items = data;
//         _filteredItems = List.from(data);
//         isLoading = false;
//       });

//     } catch (e) {
//       print("ERROR LAPORAN: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   String formatRupiah(dynamic number) {
//     return "Rp ${number.toString()}";
//   }

//   String formatDate(String? date) {
//     if (date == null) return "-";
//     try {
//       final dt = DateTime.parse(date);
//       return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
//     } catch (_) {
//       return date;
//     }
//   }

//   void _filterList(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredItems = List.from(items);
//       } else {
//         _filteredItems = items.where((item) {
//           return item.values.any((value) {
//             return value.toString().toLowerCase().contains(query.toLowerCase());
//           });
//         }).toList();
//       }
//       _sortData();
//     });
//   }

//   void _onSort(int columnIndex, bool ascending) {
//     if (columnIndex == 0) return;
//     setState(() {
//       _sortColumnIndex = columnIndex;
//       _sortAscending = ascending;
//       _sortData();
//     });
//   }

//   void _sortData() {
//     if (_sortColumnIndex == null) return;
//     final ci = _sortColumnIndex!;
//     final asc = _sortAscending;
//     _filteredItems.sort((a, b) {
//       int result;
//       switch (ci) {
//         case 1: result = (a['id_pembelian']?.toString() ?? '').compareTo(b['id_pembelian']?.toString() ?? ''); break;
//         case 2: result = (a['tanggal_pembelian']?.toString() ?? '').compareTo(b['tanggal_pembelian']?.toString() ?? ''); break;
//         case 3: result = ((a['total_harga'] ?? 0) as num).compareTo((b['total_harga'] ?? 0) as num); break;
//         case 4: result = (a['id_penerimaan']?.toString() ?? '').compareTo(b['id_penerimaan']?.toString() ?? ''); break;
//         case 5: result = (a['tanggal_penerimaan']?.toString() ?? '').compareTo(b['tanggal_penerimaan']?.toString() ?? ''); break;
//         case 6: result = (a['status']?.toString() ?? '').compareTo(b['status']?.toString() ?? ''); break;
//         default: return 0;
//       }
//       return asc ? result : -result;
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // --- FUNGSI DATE PICKER POP UP ---
//   void _closeDatePickerPopup() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }

//   void _showDatePickerPopup() {
//     if (_overlayEntry != null) {
//       _closeDatePickerPopup();
//       return;
//     }

//     DateTime tempStart = _startDate ?? DateTime.now();
//     DateTime tempEnd = _endDate ?? DateTime.now();

//     final renderBox = _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
//     final size = renderBox.size;
//     final offset = renderBox.localToGlobal(Offset.zero);

//     _overlayEntry = OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: _closeDatePickerPopup,
//               child: Container(color: Colors.transparent),
//             ),
//           ),
//           Positioned(
//             top: offset.dy + size.height + 8,
//             left: offset.dx,
//             child: Material(
//               elevation: 8,
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 width: 340, 
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       height: 280, 
//                       child: SfDateRangePicker(
//                         selectionMode: DateRangePickerSelectionMode.range, 
//                         initialSelectedRange: PickerDateRange(tempStart, tempEnd),
//                         selectionColor: const Color(0xFF1E293B),
//                         startRangeSelectionColor: const Color(0xFF1E293B),
//                         endRangeSelectionColor: const Color(0xFF1E293B),
//                         rangeSelectionColor: const Color(0xFF1E293B).withOpacity(0.1),
//                         todayHighlightColor: const Color(0xFF1E293B),
//                         onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
//                           if (args.value is PickerDateRange) {
//                             tempStart = args.value.startDate ?? tempStart;
//                             tempEnd = args.value.endDate ?? args.value.startDate ?? tempEnd;
//                           }
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         TextButton(
//                           onPressed: _closeDatePickerPopup,
//                           child: const Text('Batal', style: TextStyle(color: Colors.grey)),
//                         ),
//                         const SizedBox(width: 10),
//                         ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _startDate = tempStart;
//                               _endDate = tempEnd;
//                             });
//                             _closeDatePickerPopup();
//                             loadData(); // Otomatis refresh data saat disimpen
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF1E293B),
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                           ),
//                           child: const Text('Simpan'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);
//   }

//   String _getButtonLabel() {
//     if (_startDate == null || _endDate == null) return 'Filter Periode';
//     return '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
//   }
//   // ---------------------------------

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFFF1F5F9),
//       padding: const EdgeInsets.all(30.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const GlobalAppBar(title: 'Laporan Pembelian'),
//           const SizedBox(height: 20),

//           // =========================
//           // BARIS AKSI
//           // =========================
//           SizedBox(
//             height: 50,
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 final isDesktop = constraints.maxWidth > 1000;
//                 final row = Row(
//                 children: [
//               // --- TOMBOL FILTER YANG SUDAH DIUPDATE ---
//               ElevatedButton.icon(
//                 key: _filterButtonKey, // Kunci ditambahkan
//                 onPressed: _showDatePickerPopup, // Fungsi dipanggil
//                 icon: const Icon(Icons.calendar_month_outlined, size: 20),
//                 label: Text(_getButtonLabel()), // Text dibuat dinamis
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: const Color(0xFF1E293B),
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   elevation: 0,
//                 ),
//               ),
//               const SizedBox(width: 20),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String?>(
//                     value: _selectedStatus,
//                     hint: const Text('Status'),
//                     items: const [
//                       DropdownMenuItem(value: null, child: Text('Semua')),
//                       DropdownMenuItem(value: 'proses', child: Text('Proses')),
//                       DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedStatus = value;
//                       });
//                       loadData();
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 20),
//               isDesktop
//                   ? Expanded(
//                       child: TextField(
//                         controller: _searchController,
//                         onChanged: _filterList,
//                         decoration: InputDecoration(
//                           hintText: 'Cari ID Pembelian atau Penerimaan...',
//                           prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: const BorderSide(color: Colors.blue),
//                           ),
//                         ),
//                       ),
//                     )
//                   : SizedBox(
//                       width: 250,
//                       height: 50,
//                       child: TextField(
//                         controller: _searchController,
//                         onChanged: _filterList,
//                         decoration: InputDecoration(
//                           hintText: 'Cari ID Pembelian atau Penerimaan...',
//                           prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: const BorderSide(color: Colors.blue),
//                           ),
//                         ),
//                       ),
//                     ),
//               const SizedBox(width: 20),
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   try {
//                     final pdfBytes = await LaporanPembelianPdfService.generateLaporanPembelianPdf(
//                       items: _filteredItems,
//                       startDate: _startDate,
//                       endDate: _endDate,
//                       status: _selectedStatus,
//                     );
//                     final filename = _startDate != null && _endDate != null
//                         ? 'laporan_pembelian_${LaporanPembelianPdfService.formatDate(_startDate)}_${LaporanPembelianPdfService.formatDate(_endDate)}.pdf'
//                         : 'laporan_pembelian.pdf';
//                     LaporanPembelianPdfService.downloadPdf(pdfBytes, filename);
//                   } catch (e) {
//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Gagal cetak: ${e.toString().replaceAll("Exception: ", "")}'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   }
//                 },
//                 icon: const Icon(Icons.print_outlined, size: 20),
//                 label: const Text('Cetak Laporan'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E293B),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               ],
//             );
//             return isDesktop ? row : SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: row,
//             );
//           },
//           ),
//           ),

//           const SizedBox(height: 30),

//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : GlobalDataTable(
//                     sortColumnIndex: _sortColumnIndex,
//                     sortAscending: _sortAscending,
//                     columns: [
//                       const DataColumn(label: Text('No')),
//                       DataColumn(label: const Text('ID Pembelian'), onSort: _onSort),
//                       DataColumn(label: const Text('Tgl Beli'), onSort: _onSort),
//                       DataColumn(label: const Text('Total Harga'), onSort: _onSort),
//                       DataColumn(label: const Text('ID Penerimaan'), onSort: _onSort),
//                       DataColumn(label: const Text('Tgl Terima'), onSort: _onSort),
//                       DataColumn(label: const Text('Status'), onSort: _onSort),
//                     ],
//                     rows: List.generate(_filteredItems.length, (index) {
//                       final item = _filteredItems[index];

//                       String statusText = item["status"] ?? "Baru";

//                       return _buildDataRow(
//                         (index + 1).toString(),
//                         item["id_pembelian"] ?? '-',
//                         formatDate(item["tanggal_pembelian"]),
//                         formatRupiah(item["total_harga"]),
//                         item["id_penerimaan"] == 0
//                             ? "-"
//                             : item["id_penerimaan"].toString(),
//                         formatDate(item["tanggal_penerimaan"]),
//                         statusText,
//                       );
//                     }),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   //TIDAK DIUBAH
//   DataRow _buildDataRow(String no, String idPembelian, String tglBeli,
//       String total, String idPenerimaan, String tglTerima, String status) {

//     Color statusColor = Colors.grey;
//     if (status == 'Selesai') {
//       statusColor = Colors.green;
//     } else if (status == 'Proses') {
//       statusColor = Colors.orange;
//     }

//     return DataRow(
//       cells: [
//         DataCell(Text(no)),
//         DataCell(Text(idPembelian,
//             style: const TextStyle(fontWeight: FontWeight.bold))),
//         DataCell(Text(tglBeli)),
//         DataCell(Text(total)),
//         DataCell(Text(idPenerimaan,
//             style: const TextStyle(color: Colors.blueGrey))),
//         DataCell(Text(tglTerima)),
//         DataCell(Text(status,
//             style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
//       ],
//     );
//   }
// }