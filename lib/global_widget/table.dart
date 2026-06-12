import 'package:flutter/material.dart';
import 'dart:math'; // Diperlukan untuk fungsi min

class GlobalDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int rowsPerPage; // Jumlah baris per halaman

  const GlobalDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10, // Default 10 baris per halaman, bisa kamu ganti
  });

  @override
  State<GlobalDataTable> createState() => _GlobalDataTableState();
}

class _GlobalDataTableState extends State<GlobalDataTable> {
  int _currentPage = 0;

  @override
  void didUpdateWidget(GlobalDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logika Slicing Data (Memotong list rows berdasarkan halaman)
    final int totalPages = (widget.rows.length / widget.rowsPerPage).ceil();
    final int startIndex = _currentPage * widget.rowsPerPage;
    final int endIndex = min(startIndex + widget.rowsPerPage, widget.rows.length);
    final List<DataRow> paginatedRows = widget.rows.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Tabel Data
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowHeight: 60,
                        dataRowMaxHeight: 65,
                        columnSpacing: 40,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        columns: widget.columns,
                        rows: paginatedRows, // Menggunakan list yang sudah di-slice
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Kontrol Navigasi Halaman
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Halaman ${_currentPage + 1} dari $totalPages'),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}