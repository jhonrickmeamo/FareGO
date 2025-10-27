import 'package:farego/afterScan/livetracking.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              onDetect: (capture) async {
                if (capture.barcodes.isEmpty) return;

                final barcode = capture.barcodes.first;
                final value = barcode.rawValue;

                if (value == null || value.isEmpty) return;
                if (_navigated) return;

                setState(() {
                  qrText = value;
                  _navigated = true;
                });

                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('jeepneyIDs')
                      .doc(value)
                      .get();

                  if (!doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Jeepney not found.")),
                    );
                    _navigated = false;
                    return;
                  }

                  final data = doc.data()!;
                  final jeepneyNumber =
                      data['jeepneyNumber'] ?? 'Unknown Jeepney';
                  final driverName = data['driverName'] ?? 'Unknown Driver';

                  // Optional delay for smoother transition
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveTracking(
                          jeepneyID: value,
                          jeepneyNumber: jeepneyNumber,
                          driverName: driverName,
                          paymentMethod:
                              widget.paymentMethod, // 👈 from popup.dart
                          discount: widget.discount, // 👈 from popup.dart
                        ),
                      ),
                    );
                  });
                } catch (e) {
                  print("Error fetching jeepney data: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error fetching data: $e")),
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
