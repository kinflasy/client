class FgaConfig {
  static const host = String.fromEnvironment(
    'OPENFGA_HOST',
    defaultValue: 'http://10.0.0.45:8090',
  );

  static const storeId = String.fromEnvironment(
    'OPENFGA_STORE_ID',
    defaultValue: '01KNTK3FMFD2EFFTNXWMKJ8QVK',
  );

  static const modelId = String.fromEnvironment(
    'OPENFGA_AUTHORIZATION_MODEL_ID',
    defaultValue: '01KNTK3FNQ6PT88B7E0JV40SHQ',
  );

  static String get checkUrl => '$host/stores/$storeId/check';
}
