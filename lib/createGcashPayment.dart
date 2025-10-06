import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> createGcashPayment(double amount, String description) async {
  final secretKey = dotenv.env['stripeTestSKey'];

  if (secretKey == null || secretKey.isEmpty) {
    throw Exception("PayMongo Secret Key not found. Did you load the .env?");
  }

  final url = Uri.parse("https://api.paymongo.com/v1/sources");

  final headers = {
    "Authorization": "Basic ${base64Encode(utf8.encode("$secretKey:"))}",
    "Content-Type": "application/json",
  };

  final body = jsonEncode({
    "data": {
      "attributes": {
        "amount": (amount * 100).toInt(), // PayMongo uses centavos
        "redirect": {
          "success": "https://yourapp.com/success",
          "failed": "https://yourapp.com/failed",
        },
        "type": "gcash",
        "currency": "PHP",
        "description": description,
      }
    }
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    final checkoutUrl = data['data']['attributes']['redirect']['checkout_url'];

    // ✅ Open the GCash page in browser or in-app webview
    // Example using url_launcher:
    // await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);

    print("Redirect to: $checkoutUrl");
  } else {
    print("Payment failed: ${response.body}");
    throw Exception("Failed to create payment");
  }
}
