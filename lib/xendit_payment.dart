import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> createXenditInvoice(double amount, String description) async {
  final secretKey = dotenv.env['xenditTestSKey'];
  final url = Uri.parse('https://api.xendit.co/v2/invoices');

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Basic ${base64Encode(utf8.encode('$secretKey:'))}',
  };

  final body = jsonEncode({
    'external_id': 'invoice_${DateTime.now().millisecondsSinceEpoch}',
    'amount': amount,
    'description': description,
    'currency': 'PHP',
    'success_redirect_url': 'myapp://payment-success',
    'failure_redirect_url': 'myapp://payment-failed',
  });
  

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return data['invoice_url']; // URL to open in WebView or browser
  } else {
    throw Exception('Failed to create invoice: ${response.body}');
  }
}
