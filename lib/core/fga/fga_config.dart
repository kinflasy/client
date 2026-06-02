class FgaConfig {
  static const host = String.fromEnvironment(
    'OPENFGA_HOST',
    // defaultValue: 'https://openfga-production-c15b.up.railway.app',
  );

  static const storeId = String.fromEnvironment(
    'OPENFGA_STORE_ID',
    // defaultValue: '01KNWV2CX1MR27WHJWW18HVJMY',
  );

  static const modelId = String.fromEnvironment(
    'OPENFGA_AUTHORIZATION_MODEL_ID',
    // defaultValue: '01KNWV2D28Z7F5YYR3XSTFB0M4',
  );

  static String get checkUrl => '$host/stores/$storeId/check';
}
