import 'dart:math';

import 'package:flutter/material.dart';

class GlobalDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final List<int> rowsPerPageOptions;

  const GlobalDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.rowsPerPageOptions = const [10, 25, 50, 100],
  });

  @override
  State<GlobalDataTable> createState() => _GlobalDataTableState();
}

class _GlobalDataTableState extends State<GlobalDataTable> {
  int _currentPage = 0;
  int _rowsPerPage = 10;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPageOptions.isNotEmpty
        ? widget.rowsPerPageOptions.first
        : 10;
  }

  @override
  void didUpdateWidget(GlobalDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      _currentPage = 0;
    }
  }

  int get _effectiveRowsPerPage =>
      _showAll ? widget.rows.length : _rowsPerPage;

  @override
  Widget build(BuildContext context) {
    final int totalPages = _showAll || widget.rows.isEmpty
        ? 1
        : (widget.rows.length / _rowsPerPage).ceil();
    final int startIndex = _currentPage * _effectiveRowsPerPage;
    final int endIndex =
        min(startIndex + _effectiveRowsPerPage, widget.rows.length);
    final List<DataRow> paginatedRows =
        widget.rows.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowHeight: 60,
                        dataRowMaxHeight: 65,
                        columnSpacing: 40,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        sortColumnIndex: widget.sortColumnIndex,
                        sortAscending: widget.sortAscending,
                        columns: widget.columns,
                        rows: paginatedRows,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.rows.isNotEmpty) _buildBottomControls(totalPages),
      ],
    );
  }

  Widget _buildBottomControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildShowEntriesDropdown(),
          if (!_showAll && totalPages > 1) _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildShowEntriesDropdown() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Show ',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _showAll ? -1 : _rowsPerPage,
              isDense: true,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.grey.shade800,
                fontSize: 13,
              ),
              items: [
                ...widget.rowsPerPageOptions.map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option.toString()),
                  ),
                ),
                const DropdownMenuItem(
                  value: -1,
                  child: Text('All'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == -1) {
                    _showAll = true;
                  } else {
                    _showAll = false;
                    _rowsPerPage = value!;
                    _currentPage = 0;
                  }
                });
              },
            ),
          ),
        ),
        Text(
          ' entries',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Halaman ${_currentPage + 1} dari $totalPages',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
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
    );
  }
}
