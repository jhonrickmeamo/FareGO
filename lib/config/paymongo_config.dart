import 'package:farego/api.dart';

class payMongoConfig {
  static const bool useLive = false;

  static String get publicKey => useLive ? stripeLivePKey : stripeTestPKey;

  static String get secretKey => useLive ? stripeLiveSKey : stripeTestSKey;

  static String get baseUrl => "https://api.paymongo.com/v1";
}
