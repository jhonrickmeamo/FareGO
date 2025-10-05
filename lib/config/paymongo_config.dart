import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayMongoConfig {
  static const bool useLive = false;

  static String get publicKey => useLive
      ? dotenv.env['STRIPE_LIVE_PKEY'] ?? ''
      : dotenv.env['STRIPE_TEST_PKEY'] ?? '';

  static String get secretKey => useLive
      ? dotenv.env['STRIPE_LIVE_SKEY'] ?? ''
      : dotenv.env['STRIPE_TEST_SKEY'] ?? '';

  static String get baseUrl => "https://api.paymongo.com/v1";
}
