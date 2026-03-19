import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../data/models/transaction_model.dart';
import '../../../../core/constants/category_data.dart';

/// Generates a monthly finance PDF report.
class PdfService {
  /// Creates the PDF and returns the bytes.
  /// On native platforms, also saves to temp dir and returns [File].
  /// On web, returns null for file but bytes can be used directly.
  Future<Uint8List> generatePdfBytes({
    required int month,
    required int year,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = _buildPdf(month: month, year: year, transactions: transactions);
    return pdf.save();
  }

  /// Creates the PDF, saves to temp dir, and returns the [File].
  /// Only works on native platforms (not web).
  Future<File> generateMonthlyReport({
    required int month,
    required int year,
    required List<TransactionModel> transactions,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'generateMonthlyReport không hỗ trợ trên Web. Dùng generatePdfBytes() thay thế.',
      );
    }
    final pdfBytes = await generatePdfBytes(
      month: month,
      year: year,
      transactions: transactions,
    );
    final dir = await getTemporaryDirectory();
    final mStr = month.toString().padLeft(2, '0');
    final file = File('${dir.path}/finance_report_${mStr}_$year.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  pw.Document _buildPdf({
    required int month,
    required int year,
    required List<TransactionModel> transactions,
  }) {
    final pdf = pw.Document();

    // ── aggregate ────────────────────────────────────────────────────────
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryBreakdown = {};

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        categoryBreakdown[t.categoryId] =
            (categoryBreakdown[t.categoryId] ?? 0) + t.amount;
      }
    }

    final balance = totalIncome - totalExpense;

    // ── build PDF pages ──────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Text(
                'BÁO CÁO TÀI CHÍNH',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Tháng $month, $year',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.Divider(height: 24),

            // Summary
            pw.Text('Tóm tắt', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _summaryRow('Tổng thu nhập', totalIncome),
            _summaryRow('Tổng chi tiêu', totalExpense),
            _summaryRow('Số dư', balance),
            pw.Divider(height: 24),

            // Category breakdown
            if (categoryBreakdown.isNotEmpty) ...[
              pw.Text('Chi tiết theo danh mục',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Danh mục', 'Số tiền (₫)', 'Tỉ lệ (%)'],
                data: categoryBreakdown.entries.map((e) {
                  final cat = CategoryModel.findById(e.key);
                  final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0;
                  return [
                    cat?.name ?? e.key,
                    _fmt(e.value),
                    '${pct.toStringAsFixed(1)}%',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.center,
                },
              ),
              pw.Divider(height: 24),
            ],

            // Transaction list
            pw.Text('Danh sách giao dịch',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Ngày', 'Danh mục', 'Ghi chú', 'Số tiền (₫)'],
              data: transactions.map((t) {
                final cat = CategoryModel.findById(t.categoryId);
                final d = t.date;
                final sign = t.isIncome ? '+' : '-';
                return [
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                  cat?.name ?? t.categoryId,
                  t.note ?? '',
                  '$sign${_fmt(t.amount)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
            ),

            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Text(
                'Tạo bởi Smart Expense',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _summaryRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(_fmt(amount)),
      ],
    );
  }

  String _fmt(double v) {
    // Simple thousands-separator formatter
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0 && s[i] != '-') buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
