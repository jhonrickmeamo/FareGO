import 'package:farego/afterScan/livetracking.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

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
                final barcode = capture.barcodes.first;
                final value = barcode.rawValue ?? 'No QR code detected';

                if (!_navigated &&
                    value.isNotEmpty &&
                    value != 'No QR code detected') {
                  setState(() {
                    qrText = value;
                    _navigated = true;
                  });

                  // Example expected value: "JEEP001"
                  // You can also parse JSON if your QR contains more data
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTracking(
                        jeepneyID: value, // 👈 Pass jeepney ID here
                      ),
                    ),
                  );
                }
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
