import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PaymentCompletedPage extends StatefulWidget {
  final String date;
  final String startLocation;
  final String endLocation;
  final String fare; // already discounted
  final String paymentMethod;
  final String discount;
  final String jeepneyID;
  final String driverName;
  final String jeepneyNumber;

  const PaymentCompletedPage({
    super.key,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.paymentMethod,
    required this.discount,
    required this.jeepneyID,
    required this.driverName,
    required this.jeepneyNumber,
  });

  @override
  State<PaymentCompletedPage> createState() => _PaymentCompletedPageState();
}

class _PaymentCompletedPageState extends State<PaymentCompletedPage> {
  bool _isTripSaved = false;

  @override
  void initState() {
    super.initState();
    // If payment is Cash, save immediately
    if (widget.paymentMethod == "Cash") {
      _saveTrip();
    }
  }

  Future<String> _getDeviceUniqueId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "unknown_android";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios";
    }
    return "unknown_device";
  }

  Future<void> _saveTrip({String? referenceNumber}) async {
    if (_isTripSaved) return; // Prevent double saving
    final userId = await _getDeviceUniqueId();
    final tripsRef = FirebaseFirestore.instance
        .collection("User")
        .doc(userId)
        .collection("Trips");

    await tripsRef.add({
      "date": widget.date,
      "startLocation": widget.startLocation,
      "endLocation": widget.endLocation,
      "total": widget.fare,
      "paymentMethod": widget.paymentMethod,
      "discount": widget.discount,
      "jeepneyID": widget.jeepneyID,
      "driverName": widget.driverName,
      "jeepneyNumber": widget.jeepneyNumber,
      "referenceNumber": referenceNumber ?? "",
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pending",
    });

    setState(() {
      _isTripSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Trip saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openGCashApp(BuildContext context) async {
    const gcashAndroidUrl = 'gcash://';
    const gcashPlayStoreUrl =
        'https://play.google.com/store/apps/details?id=com.globe.gcash.android';
    const gcashIOSUrl = 'gcash://';

    try {
      if (Platform.isAndroid) {
        final uri = Uri.parse(gcashAndroidUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(Uri.parse(gcashPlayStoreUrl),
              mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        final uri = Uri.parse(gcashIOSUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(
            Uri.parse('https://apps.apple.com/ph/app/gcash/id520020791'),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      await launchUrl(Uri.parse(gcashPlayStoreUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showReferenceInputDialog() async {
    final TextEditingController _refController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Enter Reference Number"),
        content: TextField(
          controller: _refController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter GCash reference number",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final refNumber = _refController.text.trim();
              if (refNumber.isEmpty) return;

              Navigator.pop(context);
              await _saveTrip(referenceNumber: refNumber);

              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Payment Recorded"),
                  content: const Text(
                      "Your GCash payment reference has been recorded."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.asset(imagePath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3ADDBC), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "🧾 Transaction Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow("Date", widget.date),
                  _buildDetailRow("Start Location", widget.startLocation),
                  _buildDetailRow("End Location", widget.endLocation),
                  _buildDetailRow("Payment Method", widget.paymentMethod),
                  _buildDetailRow("Discount", widget.discount),
                  _buildDetailRow("Jeepney Number", widget.jeepneyNumber),
                  _buildDetailRow("Driver Name", widget.driverName),
                  const Divider(thickness: 1.5),
                  _buildDetailRow("Total Fare", "₱${widget.fare}",
                      isHighlight: true),
                  const SizedBox(height: 20),

                  // GCash QR Section
                  if (widget.paymentMethod == "GCash") ...[
                    const Text(
                      "Screenshot the QR code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showFullImage('assets/images/gcashQR.png'),
                      child: Image.asset(
                        'assets/images/gcashQR.png',
                        height: 150,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text(
                            "QR code not found",
                            style: TextStyle(color: Colors.red),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Slide to pay button
                  if (widget.paymentMethod == "GCash")
                    SlideAction(
                      text: 'Slide to Pay via GCash',
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      innerColor: Colors.white.withOpacity(0.2),
                      outerColor: Colors.green,
                      borderRadius: 16,
                      elevation: 4,
                      onSubmit: () async {
                        await _openGCashApp(context);
                        await _showReferenceInputDialog();
                      },
                    )
                  else
                    Column(
                      children: const [
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 80),
                        SizedBox(height: 10),
                        Text(
                          "Payment Successful!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isHighlight ? Colors.green[700] : Colors.black87,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
