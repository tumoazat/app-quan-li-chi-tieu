import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../providers/transaction_provider.dart';
import '../data/pdf_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

/// Use case: generate a PDF report for a given month and share it.
class ExportReportUseCase {
  final PdfService _pdfService;
  final TransactionRepository _transactionRepository;

  const ExportReportUseCase(this._pdfService, this._transactionRepository);

  Future<void> call({
    required String userId,
    required int month,
    required int year,
  }) async {
    final transactions = await _transactionRepository
        .getTransactionsByMonth(userId, year, month)
        .first;

    if (kIsWeb) {
      // On web: generate PDF bytes and trigger browser download
      final bytes = await _pdfService.generatePdfBytes(
        month: month,
        year: year,
        transactions: transactions,
      );
      final mStr = month.toString().padLeft(2, '0');
      final fileName = 'finance_report_${mStr}_$year.pdf';
      
      // Use Share.shareXFiles with XFile.fromData for web
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
        subject: 'Báo cáo tài chính tháng $month/$year',
      );
    } else {
      // On native platforms: save to temp file and share
      final file = await _pdfService.generateMonthlyReport(
        month: month,
        year: year,
        transactions: transactions,
      );
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Báo cáo tài chính tháng $month/$year',
      );
    }
  }
}

/// Provider for [ExportReportUseCase].
final exportReportUseCaseProvider = Provider<ExportReportUseCase>((ref) {
  return ExportReportUseCase(
    ref.read(pdfServiceProvider),
    ref.read(transactionRepositoryProvider),
  );
});
