import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPaymentPage extends StatelessWidget {
  final String paymentUrl;

  const WebViewPaymentPage({super.key, required this.paymentUrl});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(paymentUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('myapp://payment-success')) {
              Navigator.pop(context, true); // success
              return NavigationDecision.prevent;
            } else if (request.url.contains('myapp://payment-failed')) {
              Navigator.pop(context, false); // failed
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: WebViewWidget(controller: controller),
    );
  }
}