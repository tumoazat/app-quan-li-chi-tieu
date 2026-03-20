import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/receipt_ocr_service.dart';

class ReceiptCameraScreen extends StatefulWidget {
  const ReceiptCameraScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen> {
  final _receiptOCRService = ReceiptOCRService();
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _captureAndProcess() async {
    try {
      setState(() => _isProcessing = true);

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final result = await _receiptOCRService.extractReceiptInfo(image.path);

      if (mounted) {
        if (result['success']) {
          Navigator.pop(context, {
            'amount': result['amount'],
            'category': result['category'],
            'description': result['description'],
            'date': result['date'],
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['error']}')),
          );
        }
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 60,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Scan your receipt',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo of your receipt to auto-fill transaction details',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.tonal(
              onPressed: _isProcessing ? null : _captureAndProcess,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Take Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _receiptOCRService.dispose();
    super.dispose();
  }
}
