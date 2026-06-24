// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';
// import '../../global_widget/app_bar.dart';
// import '../../global_widget/table.dart';
// import '../../service/laporan_penjualan_service.dart';
// import '../../service/laporan_penjualan_pdf_service.dart';

// class LaporanPenjualanScreen extends StatefulWidget {
//   const LaporanPenjualanScreen({super.key});

//   @override
//   State<LaporanPenjualanScreen> createState() => _LaporanPenjualanScreenState();
// }

// class _LaporanPenjualanScreenState extends State<LaporanPenjualanScreen> {
//   final GlobalKey _filterButtonKey = GlobalKey();
//   OverlayEntry? _overlayEntry;
//   DateTime? _startDate;
//   DateTime? _endDate;

//   final TextEditingController _nominalMinController = TextEditingController();
//   final TextEditingController _nominalMaxController = TextEditingController();

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
//     setState(() => isLoading = true);

//     try {
//       String? startDateStr;
//       String? endDateStr;

//       if (_startDate != null) {
//         startDateStr =
//             '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
//       }
//       if (_endDate != null) {
//         endDateStr =
//             '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
//       }

//       final data = await LaporanPenjualanService.getLaporanPenjualan(
//         startDate: startDateStr,
//         endDate: endDateStr,
//         nominalMin:
//             _nominalMinController.text.isNotEmpty ? _nominalMinController.text : null,
//         nominalMax:
//             _nominalMaxController.text.isNotEmpty ? _nominalMaxController.text : null,
//       );

//       data.sort((a, b) {
//         final tglA = DateTime.tryParse(a['tanggal_penjualan'] ?? '') ?? DateTime(2000);
//         final tglB = DateTime.tryParse(b['tanggal_penjualan'] ?? '') ?? DateTime(2000);
//         return tglA.compareTo(tglB);
//       });

//       setState(() {
//         items = data;
//         _filteredItems = List.from(data);
//         isLoading = false;
//       });
//     } catch (e) {
//       print("ERROR LAPORAN PENJUALAN: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   String formatRupiah(dynamic number) {
//     if (number == null) return "Rp 0";
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
//           }).toList();
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
//         case 1:
//           result = (a['nomer_penjualan'] ?? '').toString().compareTo(
//               (b['nomer_penjualan'] ?? '').toString());
//           break;
//         case 2:
//           result = (a['tanggal_penjualan'] ?? '').toString().compareTo(
//               (b['tanggal_penjualan'] ?? '').toString());
//           break;
//         case 3:
//           result = (a['nama_customer'] ?? '').toString().compareTo(
//               (b['nama_customer'] ?? '').toString());
//           break;
//         case 4:
//           result = ((a['jumlah_produk_dipesan'] ?? 0) as num)
//               .compareTo((b['jumlah_produk_dipesan'] ?? 0) as num);
//           break;
//         case 5:
//           result = ((a['total_harga'] ?? 0) as num)
//               .compareTo((b['total_harga'] ?? 0) as num);
//           break;
//         default:
//           return 0;
//       }
//       return asc ? result : -result;
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

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

//     final renderBox =
//         _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
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
//                     const Text('Pilih Periode',
//                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       height: 280,
//                       child: SfDateRangePicker(
//                         selectionMode: DateRangePickerSelectionMode.range,
//                         initialSelectedRange: PickerDateRange(tempStart, tempEnd),
//                         selectionColor: const Color(0xFF1E293B),
//                         startRangeSelectionColor: const Color(0xFF1E293B),
//                         endRangeSelectionColor: const Color(0xFF1E293B),
//                         rangeSelectionColor:
//                             const Color(0xFF1E293B).withOpacity(0.1),
//                         todayHighlightColor: const Color(0xFF1E293B),
//                         onSelectionChanged:
//                             (DateRangePickerSelectionChangedArgs args) {
//                           if (args.value is PickerDateRange) {
//                             tempStart = args.value.startDate ?? tempStart;
//                             tempEnd = args.value.endDate ??
//                                 args.value.startDate ??
//                                 tempEnd;
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
//                           child:
//                               const Text('Batal', style: TextStyle(color: Colors.grey)),
//                         ),
//                         const SizedBox(width: 10),
//                         ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _startDate = tempStart;
//                               _endDate = tempEnd;
//                             });
//                             _closeDatePickerPopup();
//                             loadData();
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF1E293B),
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8)),
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

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFFF1F5F9),
//       padding: const EdgeInsets.all(30.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const GlobalAppBar(title: 'Laporan Penjualan'),
//           const SizedBox(height: 20),

//           SizedBox(
//             height: 50,
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 final isDesktop = constraints.maxWidth > 1000;
//                 final row = Row(
//                 children: [
//                   SizedBox(
//                     height: 50,
//                     child: ElevatedButton.icon(
//                       key: _filterButtonKey,
//                       onPressed: _showDatePickerPopup,
//                       icon: const Icon(Icons.calendar_month_outlined, size: 20),
//                       label: Text(_getButtonLabel()),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: const Color(0xFF1E293B),
//                         padding:
//                             const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           side: BorderSide(color: Colors.grey.shade300),
//                         ),
//                         elevation: 0,
//                       ),
//                     ),
//                   ),
//                 const SizedBox(width: 10),
//                 SizedBox(
//                   width: 150,
//                   height: 50,
//                   child: TextField(
//                     controller: _nominalMinController,
//                     decoration: InputDecoration(
//                       labelText: 'Batas Minimum',
//                       prefixIcon:
//                           const Icon(Icons.money, color: Colors.grey, size: 18),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.blue),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 SizedBox(
//                   width: 150,
//                   height: 50,
//                   child: TextField(
//                     controller: _nominalMaxController,
//                     decoration: InputDecoration(
//                       labelText: 'Batas Maksimum',
//                       prefixIcon:
//                           const Icon(Icons.money, color: Colors.grey, size: 18),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.blue),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 SizedBox(
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       loadData();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1E293B),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('Terapkan'),
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 isDesktop
//                     ? Expanded(
//                         child: TextField(
//                           controller: _searchController,
//                           onChanged: _filterList,
//                           decoration: InputDecoration(
//                             hintText: 'Cari no penjualan atau nama customer...',
//                             prefixIcon:
//                                 const Icon(Icons.search, color: Colors.grey),
//                             filled: true,
//                             fillColor: Colors.white,
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Colors.blue),
//                             ),
//                           ),
//                         ),
//                       )
//                     : SizedBox(
//                         width: 250,
//                         height: 50,
//                         child: TextField(
//                           controller: _searchController,
//                           onChanged: _filterList,
//                           decoration: InputDecoration(
//                             hintText: 'Cari no penjualan atau nama customer...',
//                             prefixIcon:
//                                 const Icon(Icons.search, color: Colors.grey),
//                             filled: true,
//                             fillColor: Colors.white,
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Colors.blue),
//                             ),
//                           ),
//                         ),
//                       ),
//                 const SizedBox(width: 20),
//                 SizedBox(
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       try {
//                         final pdfBytes = await LaporanPenjualanPdfService.generateLaporanPenjualanPdf(
//                           items: _filteredItems,
//                           startDate: _startDate,
//                           endDate: _endDate,
//                         );
//                         final filename = _startDate != null && _endDate != null
//                             ? 'laporan_penjualan_${LaporanPenjualanPdfService.formatDate(_startDate)}_${LaporanPenjualanPdfService.formatDate(_endDate)}.pdf'
//                             : 'laporan_penjualan.pdf';
//                         LaporanPenjualanPdfService.downloadPdf(pdfBytes, filename);
//                       } catch (e) {
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Gagal cetak: ${e.toString().replaceAll("Exception: ", "")}'),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       }
//                     },
//                     icon: const Icon(Icons.print_outlined, size: 20),
//                     label: const Text('Cetak Laporan'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1E293B),
//                       foregroundColor: Colors.white,
//                       padding:
//                           const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//               );
//               return isDesktop ? row : SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: row,
//               );
//             },
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
//                       DataColumn(
//                         label: const Text('No Penjualan'),
//                         onSort: _onSort,
//                       ),
//                       DataColumn(
//                         label: const Text('Tanggal Penjualan'),
//                         onSort: _onSort,
//                       ),
//                       DataColumn(
//                         label: const Text('Nama Customer'),
//                         onSort: _onSort,
//                       ),
//                       DataColumn(
//                         label: const Text('Jumlah Produk'),
//                         onSort: _onSort,
//                       ),
//                       DataColumn(
//                         label: const Text('Total Penjualan'),
//                         onSort: _onSort,
//                       ),
//                     ],
//                     rows: List.generate(_filteredItems.length, (index) {
//                       final item = _filteredItems[index];
//                       return _buildDataRow(
//                         (index + 1).toString(),
//                         item["nomer_penjualan"] ?? '-',
//                         formatDate(item["tanggal_penjualan"]),
//                         item["nama_customer"] ?? '-',
//                         (item["jumlah_produk_dipesan"] ?? 0).toString(),
//                         formatRupiah(item["total_harga"]),
//                       );
//                     }),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   DataRow _buildDataRow(String no, String noPenjualan, String tanggal,
//       String namaCustomer, String jumlahProduk, String totalPenjualan) {
//     return DataRow(
//       cells: [
//         DataCell(Text(no)),
//         DataCell(
//           Text(noPenjualan,
//               style: const TextStyle(fontWeight: FontWeight.bold)),
//         ),
//         DataCell(Text(tanggal)),
//         DataCell(Text(namaCustomer)),
//         DataCell(Text(jumlahProduk)),
//         DataCell(
//           Text(totalPenjualan,
//               style: const TextStyle(fontWeight: FontWeight.w600)),
//         ),
//       ],
//     );
//   }
// }
