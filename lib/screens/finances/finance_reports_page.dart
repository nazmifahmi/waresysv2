import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_model.dart';
import '../../services/finance_service.dart';
import '../../services/monitoring_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';
import '../finances/finance_overview_page.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/transaction_service.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';

class FinanceReportsPage extends StatefulWidget {
  @override
  State<FinanceReportsPage> createState() => _FinanceReportsPageState();

  static Future<void> exportPdfStatic(BuildContext context, DateTime start, DateTime end) async {
    final state = _FinanceReportsPageState();
    await state._exportPdf(start, end, context: context);
  }
}

class _FinanceReportsPageState extends State<FinanceReportsPage> {
  final _service = FinanceService();
  final _trxService = TransactionService();
  final _authService = AuthService();
  final _monitoringService = MonitoringService();
  String _periode = 'Bulan Ini';
  DateTime? _customStart;
  DateTime? _customEnd;

  // Create a unique key for each instance
  final _offscreenChartKey = GlobalKey();

  Stream<List<_UnifiedTransaction>> get _unifiedTransactionsStream {
    final manualStream = _service.getTransactionsStream()
      .map((list) => list.where((t) => 
        t.category != 'Penjualan (Sales)' && 
        t.category != 'Pembelian (Purchase)'
      ).toList());
    
    final salesStream = _trxService.getTransactionsStream(type: TransactionType.sales)
      .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());
    
    final purchaseStream = _trxService.getTransactionsStream(type: TransactionType.purchase)
      .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());
    
    return Rx.combineLatest3<List<FinanceTransaction>, List<TransactionModel>, List<TransactionModel>, List<_UnifiedTransaction>>(
      manualStream,
      salesStream,
      purchaseStream,
      (manual, sales, purchase) {
        final unified = <_UnifiedTransaction>[];
        unified.addAll(manual.map((t) => _UnifiedTransaction.fromFinance(t)));
        unified.addAll(sales.map((t) => _UnifiedTransaction.fromSalesPurchase(t)));
        unified.addAll(purchase.map((t) => _UnifiedTransaction.fromSalesPurchase(t)));
        unified.sort((a, b) => b.date.compareTo(a.date));
        return unified;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime start, end;
    if (_periode == 'Bulan Ini') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (_periode == 'Tahun Ini') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31);
    } else {
      start = _customStart ?? DateTime(now.year, now.month, 1);
      end = _customEnd ?? DateTime(now.year, now.month, now.day);
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Filter controls on the left
              Expanded(
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _periode,
                      items: ['Bulan Ini', 'Tahun Ini', 'Custom'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _periode = newValue;
                            if (newValue != 'Custom') {
                              _customStart = null;
                              _customEnd = null;
                            }
                          });
                        }
                      },
                    ),
                    if (_periode == 'Custom') ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(
                                start: _customStart ?? DateTime(now.year, now.month, 1),
                                end: _customEnd ?? DateTime(now.year, now.month, now.day),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                _customStart = picked.start;
                                _customEnd = picked.end;
                              });
                            }
                          },
                          child: Text(
                            '${DateFormat('dd/MM/yyyy').format(_customStart ?? DateTime(now.year, now.month, 1))} - ${DateFormat('dd/MM/yyyy').format(_customEnd ?? DateTime(now.year, now.month, now.day))}',
                            style: TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Export buttons on the right
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 36),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => _exportPdf(start, end, context: context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.table_chart),
                    label: Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 36),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => _exportExcel(start, end),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<_UnifiedTransaction>>(
            stream: _unifiedTransactionsStream,
            builder: (context, snap) {
              final data = (snap.data ?? []).where((t) =>
                !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
              final pemasukan = data.where((t) => t.type == FinanceTransactionType.income).fold(0.0, (a, b) => a + b.amount);
              final pengeluaran = data.where((t) => t.type == FinanceTransactionType.expense).fold(0.0, (a, b) => a + b.amount);
              final rekap = <String, double>{};
              for (final t in data) {
                rekap[t.category] = (rekap[t.category] ?? 0) + (t.type == FinanceTransactionType.income ? t.amount : -t.amount);
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: Text('Total Pemasukan'),
                      trailing: Text(_formatRupiah(pemasukan), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text('Total Pengeluaran'),
                      trailing: Text(_formatRupiah(pengeluaran), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Rekap per Kategori', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DataTable(
                    columnSpacing: 18,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 48,
                    columns: const [
                      DataColumn(label: SizedBox(width: 110, child: Text('Kategori'))),
                      DataColumn(label: Align(alignment: Alignment.centerRight, child: Text('Pemasukan'))),
                      DataColumn(label: Align(alignment: Alignment.centerRight, child: Text('Pengeluaran'))),
                    ],
                    rows: rekap.keys.map((cat) {
                      final pemasukanCat = data.where((t) => t.category == cat && t.type == FinanceTransactionType.income).fold(0.0, (a, b) => a + b.amount);
                      final pengeluaranCat = data.where((t) => t.category == cat && t.type == FinanceTransactionType.expense).fold(0.0, (a, b) => a + b.amount);
                      return DataRow(cells: [
                        DataCell(Text(cat, style: TextStyle(fontSize: 14))),
                        DataCell(Align(
                          alignment: Alignment.centerRight,
                          child: Text(_formatRupiah(pemasukanCat), style: TextStyle(color: Colors.green, fontSize: 14), textAlign: TextAlign.right),
                        )),
                        DataCell(Align(
                          alignment: Alignment.centerRight,
                          child: Text(_formatRupiah(pengeluaranCat), style: TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.right),
                        )),
                      ]);
                    }).toList(),
                  ),
                  if (rekap.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(child: Text('Belum ada transaksi pada periode ini', style: TextStyle(color: Colors.grey))),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double n) {
    final f = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return f.format(n);
  }

  Future<Uint8List?> _getOffscreenChartImage(BuildContext context, DateTime start, DateTime end) async {
    // Get unified transactions for chart
    final data = await _unifiedTransactionsStream.first;
    final filtered = data.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    
    // Create a new key for each chart instance
    final chartKey = GlobalKey();
    
    final daysInMonth = DateUtils.getDaysInMonth(start.year, start.month);
    final dailyIncome = List<double>.filled(daysInMonth, 0);
    final dailyExpense = List<double>.filled(daysInMonth, 0);
    for (final t in filtered) {
      final day = t.date.day - 1;
      if (t.type == FinanceTransactionType.income) {
        dailyIncome[day] += t.amount;
      } else {
        dailyExpense[day] += t.amount;
      }
    }
    final maxIncome = dailyIncome.reduce((a, b) => a > b ? a : b);
    final maxExpense = dailyExpense.reduce((a, b) => a > b ? a : b);
    final maxY = [maxIncome, maxExpense, 1].reduce((a, b) => a > b ? a : b);
    final chart = Material(
      type: MaterialType.transparency,
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: RepaintBoundary(
          key: chartKey,
          child: SizedBox(
            width: 600,
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Nominal (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    axisNameSize: 32,
                    sideTitles: SideTitles(showTitles: true, reservedSize: 60),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Tanggal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    axisNameSize: 32,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt() + 1;
                        if (day < 1 || day > daysInMonth) return Container();
                        return Text(day.toString(), style: TextStyle(fontSize: 9));
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (daysInMonth - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.15,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < daysInMonth; i++)
                        FlSpot(i.toDouble(), dailyIncome[i]),
                    ],
                    isCurved: false,
                    color: Colors.green,
                    barWidth: 2.5,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < daysInMonth; i++)
                        FlSpot(i.toDouble(), dailyExpense[i]),
                    ],
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 2.5,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(enabled: false),
              ),
            ),
          ),
        ),
      ),
    );
    final overlay = Overlay.of(context);
    if (overlay == null) return null;
    final entry = OverlayEntry(builder: (_) => Offstage(child: chart));
    overlay.insert(entry);
    await Future.delayed(Duration(milliseconds: 400));
    final boundary = chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      entry.remove();
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    entry.remove();
    return byteData?.buffer.asUint8List();
  }

  Future<void> _exportPdf(DateTime start, DateTime end, {BuildContext? context}) async {
    try {
      // Get unified transactions and balance logs
      final data = await _unifiedTransactionsStream.first;
      final filtered = data.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
      final balanceLogs = await _service.getBalanceLogsStream().first;
      final filteredLogs = balanceLogs.where((log) => !log.date.isBefore(start) && !log.date.isAfter(end)).toList();
      
      // Calculate monthly totals and balances
      final monthlyData = <String, Map<String, dynamic>>{};
      for (final t in filtered) {
        final monthKey = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] ??= {
          'income': 0.0,
          'expense': 0.0,
          'startBalance': 0.0,
          'endBalance': 0.0,
          'month': t.date,
        };
        if (t.type == FinanceTransactionType.income) {
          monthlyData[monthKey]!['income'] = monthlyData[monthKey]!['income']! + t.amount;
        } else {
          monthlyData[monthKey]!['expense'] = monthlyData[monthKey]!['expense']! + t.amount;
        }
      }

      // Add balance information
      for (final monthKey in monthlyData.keys) {
        final monthLogs = filteredLogs.where((log) => 
          log.date.year == monthlyData[monthKey]!['month'].year && 
          log.date.month == monthlyData[monthKey]!['month'].month
        ).toList();
        
        if (monthLogs.isNotEmpty) {
          monthLogs.sort((a, b) => a.date.compareTo(b.date));
          monthlyData[monthKey]!['startBalance'] = monthLogs.first.before;
          monthlyData[monthKey]!['endBalance'] = monthLogs.last.after;
        }
      }
      
      final pemasukan = filtered.where((t) => t.type == FinanceTransactionType.income).fold(0.0, (a, b) => a + b.amount);
      final pengeluaran = filtered.where((t) => t.type == FinanceTransactionType.expense).fold(0.0, (a, b) => a + b.amount);
      final rekap = <String, Map<String, double>>{};
      for (final t in filtered) {
        rekap[t.category] ??= {'in': 0.0, 'out': 0.0};
        if (t.type == FinanceTransactionType.income) {
          rekap[t.category]!['in'] = rekap[t.category]!['in']! + t.amount;
        } else {
          rekap[t.category]!['out'] = rekap[t.category]!['out']! + t.amount;
        }
      }
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Keuangan', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Periode: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}'),
              pw.SizedBox(height: 12),
              pw.Text('Total Pemasukan: ${_formatRupiah(pemasukan)}', style: pw.TextStyle(color: PdfColor.fromInt(0xFF388E3C))),
              pw.Text('Total Pengeluaran: ${_formatRupiah(pengeluaran)}', style: pw.TextStyle(color: PdfColor.fromInt(0xFFD32F2F))),
              pw.SizedBox(height: 16),
              pw.Text('Rekap per Bulan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['Bulan', 'Saldo Awal', 'Pemasukan', 'Pengeluaran', 'Saldo Akhir'],
                data: monthlyData.entries.map((e) => [
                  DateFormat('MMMM yyyy').format(e.value['month']),
                  _formatRupiah(e.value['startBalance']),
                  _formatRupiah(e.value['income']),
                  _formatRupiah(e.value['expense']),
                  _formatRupiah(e.value['endBalance']),
                ]).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Rekap per Kategori', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['Kategori', 'Pemasukan', 'Pengeluaran'],
                data: rekap.entries.map((e) => [
                  e.key,
                  _formatRupiah(e.value['in'] ?? 0),
                  _formatRupiah(e.value['out'] ?? 0),
                ]).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Detail Transaksi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['Tanggal', 'Kategori', 'Tipe', 'Jumlah', 'Keterangan', 'Sumber'],
                data: filtered.map((t) => [
                  DateFormat('dd/MM/yyyy').format(t.date),
                  t.category,
                  t.type == FinanceTransactionType.income ? 'Pemasukan' : 'Pengeluaran',
                  _formatRupiah(t.amount),
                  t.description ?? '',
                  t.source ?? 'Manual',
                ]).toList(),
              ),
            ],
          ),
        ),
      );
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/laporan_keuangan.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);

      // Record export activity in monitoring
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';
      final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
      
      await _monitoringService.logActivity(
        type: 'finance',
        action: 'export_pdf',
        userId: userId,
        userName: userName,
        description: 'Export laporan keuangan PDF periode ${DateFormat('MMMM yyyy').format(start)}',
        details: {
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
          'totalIncome': pemasukan,
          'totalExpense': pengeluaran,
          'exportType': 'PDF'
        },
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan di: ${file.path}')),
        );
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    }
  }

  Future<String> _getDownloadPath() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      Directory? directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory.path;
      }
    }
    return (await getTemporaryDirectory()).path;
  }

  Future<void> _exportExcel(DateTime start, DateTime end) async {
    try {
      // Get unified transactions and balance logs
      final data = await _unifiedTransactionsStream.first;
      final filtered = data.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
      final balanceLogs = await _service.getBalanceLogsStream().first;
      final filteredLogs = balanceLogs.where((log) => !log.date.isBefore(start) && !log.date.isAfter(end)).toList();
      
      // Calculate monthly totals and balances
      final monthlyData = <String, Map<String, dynamic>>{};
      for (final t in filtered) {
        final monthKey = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] ??= {
          'income': 0.0,
          'expense': 0.0,
          'startBalance': 0.0,
          'endBalance': 0.0,
          'month': t.date,
        };
        if (t.type == FinanceTransactionType.income) {
          monthlyData[monthKey]!['income'] = monthlyData[monthKey]!['income']! + t.amount;
        } else {
          monthlyData[monthKey]!['expense'] = monthlyData[monthKey]!['expense']! + t.amount;
        }
      }

      // Add balance information
      for (final monthKey in monthlyData.keys) {
        final monthLogs = filteredLogs.where((log) => 
          log.date.year == monthlyData[monthKey]!['month'].year && 
          log.date.month == monthlyData[monthKey]!['month'].month
        ).toList();
        
        if (monthLogs.isNotEmpty) {
          monthLogs.sort((a, b) => a.date.compareTo(b.date));
          monthlyData[monthKey]!['startBalance'] = monthLogs.first.before;
          monthlyData[monthKey]!['endBalance'] = monthLogs.last.after;
        }
      }
      
      final pemasukan = filtered.where((t) => t.type == FinanceTransactionType.income).fold(0.0, (a, b) => a + b.amount);
      final pengeluaran = filtered.where((t) => t.type == FinanceTransactionType.expense).fold(0.0, (a, b) => a + b.amount);
      final rekap = <String, Map<String, double>>{};
      for (final t in filtered) {
        rekap[t.category] ??= {'in': 0.0, 'out': 0.0};
        if (t.type == FinanceTransactionType.income) {
          rekap[t.category]!['in'] = rekap[t.category]!['in']! + t.amount;
        } else {
          rekap[t.category]!['out'] = rekap[t.category]!['out']! + t.amount;
        }
      }
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Laporan Keuangan');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Periode: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Total Pemasukan: ${_formatRupiah(pemasukan)}');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Total Pengeluaran: ${_formatRupiah(pengeluaran)}');

      // Monthly Summary
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('Rekap per Bulan');
      List<String> monthlyHeaders = ['Bulan', 'Saldo Awal', 'Pemasukan', 'Pengeluaran', 'Saldo Akhir'];
      for (int i = 0; i < monthlyHeaders.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6)).value = TextCellValue(monthlyHeaders[i]);
      }
      int monthlyRow = 7;
      for (final entry in monthlyData.entries) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: monthlyRow)).value = TextCellValue(DateFormat('MMMM yyyy').format(entry.value['month']));
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: monthlyRow)).value = TextCellValue(_formatRupiah(entry.value['startBalance']));
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: monthlyRow)).value = TextCellValue(_formatRupiah(entry.value['income']));
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: monthlyRow)).value = TextCellValue(_formatRupiah(entry.value['expense']));
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: monthlyRow)).value = TextCellValue(_formatRupiah(entry.value['endBalance']));
        monthlyRow++;
      }

      // Category Summary
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: monthlyRow + 2)).value = TextCellValue('Rekap per Kategori');
      List<String> headers = ['Kategori', 'Pemasukan', 'Pengeluaran'];
      for (int i = 0; i < headers.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: monthlyRow + 3)).value = TextCellValue(headers[i]);
      }
      int row = monthlyRow + 4;
      rekap.forEach((cat, val) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(cat);
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(_formatRupiah(val['in'] ?? 0));
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(_formatRupiah(val['out'] ?? 0));
        row++;
      });

      // Transaction Details
      Sheet detailSheet = excel['Detail Transaksi'];
      detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Detail Transaksi');
      List<String> detailHeaders = ['Tanggal', 'Kategori', 'Tipe', 'Jumlah', 'Keterangan', 'Sumber'];
      for (int i = 0; i < detailHeaders.length; i++) {
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value = TextCellValue(detailHeaders[i]);
      }
      int detailRow = 2;
      for (final t in filtered) {
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: detailRow)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(t.date));
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: detailRow)).value = TextCellValue(t.category);
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: detailRow)).value = TextCellValue(t.type == FinanceTransactionType.income ? 'Pemasukan' : 'Pengeluaran');
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: detailRow)).value = TextCellValue(_formatRupiah(t.amount));
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: detailRow)).value = TextCellValue(t.description ?? '');
        detailSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: detailRow)).value = TextCellValue(t.source ?? 'Manual');
        detailRow++;
      }

      final downloadPath = await _getDownloadPath();
      final file = File('$downloadPath/laporan_keuangan.xlsx');
      await file.writeAsBytes(excel.encode()!);
      await OpenFilex.open(file.path);

      // Record export activity in monitoring
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';
      final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
      
      await _monitoringService.logActivity(
        type: 'finance',
        action: 'export_excel',
        userId: userId,
        userName: userName,
        description: 'Export laporan keuangan Excel periode ${DateFormat('MMMM yyyy').format(start)}',
        details: {
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
          'totalIncome': pemasukan,
          'totalExpense': pengeluaran,
          'exportType': 'Excel'
        },
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel berhasil disimpan di: ${file.path}')),
        );
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat Excel: $e')),
        );
      }
    }
  }
}

class _UnifiedTransaction {
  final FinanceTransactionType type;
  final String category;
  final double amount;
  final String? description;
  final DateTime date;
  final String? customerSupplierName;
  final String? source; // 'sales', 'purchase', atau null (manual)
  final FinanceTransaction? financeTransaction;
  final TransactionModel? salesPurchaseTransaction;

  _UnifiedTransaction({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.customerSupplierName,
    this.source,
    this.financeTransaction,
    this.salesPurchaseTransaction,
  });

  factory _UnifiedTransaction.fromFinance(FinanceTransaction t) => _UnifiedTransaction(
    type: t.type,
    category: t.category,
    amount: t.amount,
    date: t.date,
    description: t.description,
    source: null,
    financeTransaction: t,
    salesPurchaseTransaction: null,
  );

  factory _UnifiedTransaction.fromSalesPurchase(TransactionModel t) => _UnifiedTransaction(
    type: t.type == TransactionType.sales ? FinanceTransactionType.income : FinanceTransactionType.expense,
    category: t.type == TransactionType.sales ? 'Penjualan (Sales)' : 'Pembelian (Purchase)',
    amount: t.total,
    date: t.createdAt,
    description: t.notes,
    customerSupplierName: t.customerSupplierName,
    source: t.type == TransactionType.sales ? 'sales' : 'purchase',
    financeTransaction: null,
    salesPurchaseTransaction: t,
  );
} 