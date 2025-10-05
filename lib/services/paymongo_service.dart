import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:farego/config/paymongo_config.dart';

class PayMongoService {
  static Map<String, String> get headers => {
    "Authorization":
        "Basic ${base64Encode(utf8.encode("${PayMongoConfig.publicKey}:"))}",
    "Content-Type": "application/json",
  };

  static Future<Map<String, dynamic>> createPaymentIntent(int amount) async {
    final url = Uri.parse("${PayMongoConfig.baseUrl}/payment_intents");

    final body = jsonEncode({
      "data": {
        "attributes": {
          "amount": amount,
          "currency": "PHP",
          "payment_method_allowed": ["gcash"],
          "capture_type": "automatic",
        },
      },
    });

    final response = await http.post(url, headers: headers, body: body);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createGCashMethod({
    required String name,
    required String email,
    required String phone,
  }) async {
    final url = Uri.parse("${PayMongoConfig.baseUrl}/payment_methods");

    final body = jsonEncode({
      "data": {
        "attributes": {
          "type": "gcash",
          "billing": {"name": name, "email": email, "phone": phone},
        },
      },
    });

    final response = await http.post(url, headers: headers, body: body);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> attachPaymentMethod(
    String intentId,
    String paymentMethodId,
  ) async {
    final url = Uri.parse(
      "${PayMongoConfig.baseUrl}/payment_intents/$intentId/attach",
    );

    final body = jsonEncode({
      "data": {
        "attributes": {"payment_method": paymentMethodId},
      },
    });

    final response = await http.post(url, headers: headers, body: body);
    return jsonDecode(response.body);
  }

  static Future<void> openCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $url";
    }
  }

  static Future<void> payWithGCash({
    required int amount,
    required String name,
    required String email,
    required String phone,
  }) async {
    final intent = await createPaymentIntent(amount);
    final intentId = intent["data"]["id"];

    final method = await createGCashMethod(
      name: name,
      email: email,
      phone: phone,
    );
    final methodId = method["data"]["id"];

    final attached = await attachPaymentMethod(intentId, methodId);
    final checkoutUrl =
        attached["data"]["attributes"]["next_action"]["redirect"]["url"];

    await openCheckout(checkoutUrl);
  }
}
