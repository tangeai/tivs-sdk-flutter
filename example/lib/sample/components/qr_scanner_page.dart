import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isProcessing = false;
  final MobileScannerController cameraController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    cameraResolution: const Size(1920, 1080),
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('扫描"调试二维码"'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        body: MobileScanner(
          controller: cameraController,
          errorBuilder: (context, error, child) => ColoredBox(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '扫码器启动失败，请确认相机权限后重试。\n${error.errorCode.message}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          onDetect: (capture) {
            if (_isProcessing) return;

            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String result = barcodes.first.rawValue ?? '';
              if (result.isNotEmpty) {
                _isProcessing = true;
                Navigator.of(context).pop(result);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
