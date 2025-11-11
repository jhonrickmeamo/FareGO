import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/scheduler.dart';

class WebViewPaymentPage extends StatefulWidget {
  final String paymentUrl;
  const WebViewPaymentPage({super.key, required this.paymentUrl});

  @override
  State<WebViewPaymentPage> createState() => _WebViewPaymentPageState();
}

class _WebViewPaymentPageState extends State<WebViewPaymentPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('myapp://payment-success')) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context, true);
              });
              return NavigationDecision.prevent;
            } else if (request.url.contains('myapp://payment-failed')) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context, false);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
