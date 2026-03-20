import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/services/receipt_ocr_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';

class ReceiptCameraScreen extends StatefulWidget {
  const ReceiptCameraScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen> {
  final _receiptOCRService = ReceiptOCRService();
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;
  File? _selectedImage;
  Map<String, dynamic>? _extractedData;

  Future<void> _captureImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        _processImage(File(image.path));
      }
    } catch (e) {
      _showError('Lỗi chụp ảnh: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        _processImage(File(image.path));
      }
    } catch (e) {
      _showError('Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      setState(() => _isProcessing = true);

      final result = await _receiptOCRService.extractReceiptInfo(imageFile.path);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _extractedData = result;
            _isProcessing = false;
          });
        } else {
          _showError('${result['error'] ?? 'Không thể nhận diện hóa đơn'}');
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      _showError('Lỗi xử lý: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _confirmData() {
    if (_extractedData != null) {
      Navigator.pop(context, {
        'amount': _extractedData!['amount'],
        'category': _extractedData!['category'],
        'description': _extractedData!['description'],
        'date': _extractedData!['date'],
      });
    }
  }

  void _resetData() {
    setState(() {
      _selectedImage = null;
      _extractedData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quét Hóa Đơn',
          style: AppTypography.headlineMedium(context),
        ),
        centerTitle: true,
      ),
      body: _isProcessing
          ? _buildProcessingScreen()
          : _extractedData != null
              ? _buildConfirmScreen()
              : _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 70,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Quét Hóa Đơn',
              style: AppTypography.displayMedium(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chụp ảnh hóa đơn để tự động nhận diện số tiền',
              style: AppTypography.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),
            
            // Camera button
            FilledButton.icon(
              onPressed: _captureImage,
              icon: const Icon(Icons.camera_alt, size: 24),
              label: const Text('Chụp Ảnh'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Gallery button
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library, size: 24),
              label: const Text('Chọn Ảnh'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang xử lý...',
            style: AppTypography.headlineMedium(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhận diện thông tin hóa đơn',
            style: AppTypography.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmScreen() {
    final amount = _extractedData?['amount'] as double? ?? 0;
    final description = _extractedData?['description'] as String? ?? '';
    final category = _extractedData?['category'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (_selectedImage != null)
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Amount card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số tiền nhận diện',
                  style: AppTypography.bodyMedium(context).copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.formatVND(amount),
                  style: AppTypography.displayLarge(context).copyWith(
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          if (description.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô tả',
                  style: AppTypography.titleMedium(context),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(description),
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Category
          if (category.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh mục',
                  style: AppTypography.titleMedium(context),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(category),
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Confirm and retry buttons
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: _confirmData,
                  icon: const Icon(Icons.check),
                  label: const Text('Xác Nhận'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Quét Lại'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _receiptOCRService.dispose();
    super.dispose();
  }
}
