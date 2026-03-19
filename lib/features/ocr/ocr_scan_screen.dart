import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';
import 'receipt_parser.dart';
import '../../core/utils/currency_formatter.dart';

/// Màn hình scan hóa đơn bằng OCR
class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final _ocrService = OcrService();
  final _imagePicker = ImagePicker();

  File? _imageFile;
  bool _isProcessing = false;
  Map<String, dynamic>? _parsedData;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _isProcessing = true;
      _parsedData = null;
    });

    try {
      // Nhận diện chữ từ ảnh
      final text = await _ocrService.recognizeText(_imageFile!);
      // Phân tích dữ liệu từ text
      final parsed = ReceiptParser.parse(text);

      if (mounted) {
        setState(() {
          _parsedData = parsed;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nhận diện: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📸 Scan Hóa Đơn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khu vực hiển thị ảnh
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Chụp hoặc chọn ảnh hóa đơn',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Nút chọn ảnh
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Thư viện'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kết quả xử lý
            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Đang nhận diện hóa đơn...'),
                  ],
                ),
              ),

            if (_parsedData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả nhận diện',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      // Hiển thị số tiền nếu nhận diện được
                      if (_parsedData!['amount'] != null)
                        ListTile(
                          leading: const Icon(Icons.attach_money),
                          title: const Text('Số tiền'),
                          trailing: Text(
                            CurrencyFormatter.formatVND(
                              (_parsedData!['amount'] as double),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Mô tả'),
                        subtitle: Text(_parsedData!['description'] as String),
                      ),
                      if (_parsedData!['date'] != null)
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Ngày'),
                          trailing: Text(
                            (_parsedData!['date'] as DateTime)
                                .toString()
                                .substring(0, 10),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nút sử dụng kết quả
              ElevatedButton.icon(
                onPressed: () {
                  // Trả kết quả về màn hình thêm giao dịch
                  Navigator.pop(context, _parsedData);
                },
                icon: const Icon(Icons.check),
                label: const Text('Sử dụng dữ liệu này'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
