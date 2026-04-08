class FgaConfig {
  static const host = String.fromEnvironment(
    'OPENFGA_HOST',
    defaultValue: 'http://10.0.0.45:8090',
  );

  static const storeId = String.fromEnvironment(
    'OPENFGA_STORE_ID',
    defaultValue: '01KMPE3CBAXX3X38XGTJ2G75V6',
  );

  static const modelId = String.fromEnvironment(
    'OPENFGA_AUTHORIZATION_MODEL_ID',
    defaultValue: '01KMPE3CDV6PX5KXT6TKTBTBZ6',
  );

  static String get checkUrl => '$host/stores/$storeId/check';
}
