import 'package:farego/api.dart';

class payMongoConfig {
  static const bool useLive = false;

  static String get publicKey =>
      useLive ? paymongoPublicLiveKey : paymongoPkTestKey;

  static String get secretKey =>
      useLive ? payMongoSecretLiveKey : payMongoSkTestKey;

  static String get baseUrl => "https://api.paymongo.com/v1";
}
