import 'package:farego/afterScan/livetracking.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatefulWidget {
  final String paymentMethod; // 👈 from popup.dart
  final String discount; // 👈 from popup.dart

  const QRScanner({
    super.key,
    required this.paymentMethod,
    required this.discount,
  });

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  String? qrText;
  bool _navigated = false; // Prevent multiple navigations

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'FareGO',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.green[700]),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;

                final barcode = capture.barcodes.first;
                final value = barcode.rawValue;

                if (value == null || value.isEmpty) return;
                if (_navigated) return;

                setState(() {
                  qrText = value;
                  _navigated = true;
                });

                // Optional delay for smoother transition
                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTracking(
                        jeepneyID: value, // from QR
                        paymentMethod:
                            widget.paymentMethod, // 👈 from popup.dart
                        discount: widget.discount, // 👈 from popup.dart
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qrText ?? 'Scan a QR code',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
