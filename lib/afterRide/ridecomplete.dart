import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:farego/xendit_payment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farego/webview_payment_page.dart';

class PaymentCompletedPage extends StatelessWidget {
  final String date;
  final String startLocation;
  final String endLocation;
  final String fare;

  const PaymentCompletedPage({
    super.key,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
  });

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
            colors: [
              Color(0xFF00D2A0),
              Color(0xFF3EE7C9),
            ],
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
              const Text(
                'Payment',
                style: TextStyle(
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
                      _buildDetailRow('Date', date),
                      const SizedBox(height: 12),
                      _buildDetailRow('Payment Method', 'GCash'),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle_outlined,
                              size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              startLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              size: 24, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              endLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total', '₱$fare'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(
                  builder: (context) {
                    return SlideAction(
                      outerColor: const Color(0xFF00D2A0),
                      innerColor: Colors.white,
                      text: "Slide to Confirm",
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
  try {
    // 1️⃣ Create Xendit invoice
    final checkoutUrl = await createXenditInvoice(
      double.parse(fare),
      "Fare Payment from $startLocation to $endLocation on $date",
    );

    // 2️⃣ Open inside your app (WebView)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPaymentPage(paymentUrl: checkoutUrl),
      ),
    );

    // 3️⃣ Handle redirect result
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
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
        content: Text('Payment initiation failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                    );
                  },
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
