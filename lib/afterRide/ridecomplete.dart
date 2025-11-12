import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:farego/xenditPayment.dart';
import 'package:farego/webviewPaymentpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PaymentCompletedPage extends StatefulWidget {
  final String date;
  final String startLocation;
  final String endLocation;
  final String fare;
  final String paymentMethod;
  final String jeepneyID;
  final String discountLabel;
  final String discountAmount; // numeric string, e.g. "2.00"
  final String jeepneyNumber;
  final String driverName;

  const PaymentCompletedPage({
    super.key,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.paymentMethod,
    required this.jeepneyID,
    required this.discountLabel,
    required this.discountAmount,
    required this.jeepneyNumber,
    required this.driverName,
  });

  @override
  State<PaymentCompletedPage> createState() => _PaymentCompletedPageState();
}

class _PaymentCompletedPageState extends State<PaymentCompletedPage> {
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod == "Cash") {
      _saveCashTrip();
    }
  }

  Future<String> _getDeviceId() async {
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

  Future<void> _saveCashTrip() async {
    try {
      final deviceId = await _getDeviceId();
      final tripsRef = FirebaseFirestore.instance
          .collection("User")
          .doc(deviceId)
          .collection("Trips");

      await tripsRef.add({
        "date": widget.date,
        "payment_method": widget.paymentMethod,
        "discount_label": widget.discountLabel,
        "discount_amount": widget.discountAmount,
        "start_location": widget.startLocation,
        "end_location": widget.endLocation,
        "total": widget.fare,
        "jeepneyID": widget.jeepneyID,
        "driverName": widget.driverName,
        "jeepneyNumber": widget.jeepneyNumber,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "paid", // Cash is considered paid
      });
    } catch (e) {
      // Fail silently; Cash saving does not show SnackBar
    }
  }

  Future<void> _startGcashPayment(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isProcessingPayment = true);

    try {
      final deviceId = await _getDeviceId();
      final checkoutUrl = await createXenditInvoice(
        double.parse(widget.fare),
        "Fare Payment from ${widget.startLocation} to ${widget.endLocation} on ${widget.date}",
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewPaymentPage(paymentUrl: checkoutUrl),
        ),
      );

      if (!mounted) return;

      // Save GCash result to Firebase
      final tripsRef = FirebaseFirestore.instance
          .collection("User")
          .doc(deviceId)
          .collection("Trips");

      await tripsRef.add({
        "date": widget.date,
        "payment_method": widget.paymentMethod,
        "discount_label": widget.discountLabel,
        "discount_amount": widget.discountAmount,
        "start_location": widget.startLocation,
        "end_location": widget.endLocation,
        "total": widget.fare,
        "jeepneyID": widget.jeepneyID,
        "driverName": widget.driverName,
        "jeepneyNumber": widget.jeepneyNumber,
        "timestamp": FieldValue.serverTimestamp(),
        "status": result == true ? "paid" : "failed",
      });

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful & saved'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed or cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00D2A0), Color(0xFF3EE7C9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF00D2A0),
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.paymentMethod == "Cash"
                    ? 'Payment Completed'
                    : 'GCash Payment',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction details',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', widget.date),
                      const SizedBox(height: 12),
                      _buildDetailRow('Payment Method', widget.paymentMethod),
                      const SizedBox(height: 12),
                      _buildDetailRow('Discount Type', widget.discountLabel),
                      const SizedBox(height: 8),
                      _buildDetailRow('Discount', '₱${widget.discountAmount}'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Jeepney ID', widget.jeepneyID),
                      const SizedBox(height: 12),
                      _buildDetailRow('Jeepney Driver', widget.driverName),
                      const SizedBox(height: 12),
                      _buildDetailRow('Start Location', widget.startLocation),
                      const SizedBox(height: 12),
                      _buildDetailRow('End Location', widget.endLocation),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total', '₱${widget.fare}'),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // SlideAction only for GCash
              if (widget.paymentMethod == "GCash")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SlideAction(
                    outerColor: const Color(0xFF00D2A0),
                    innerColor: Colors.white,
                    text: "Slide to Pay with GCash",
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    sliderButtonIcon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00D2A0),
                    ),
                    onSubmit: () async {
                      await _startGcashPayment(context);
                    },
                  ),
                ),

              // For Cash: show message
              if (widget.paymentMethod == "Cash")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: const [
                      Text(
                        "Please pay the driver in cash.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
