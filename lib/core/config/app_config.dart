class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.0.45:8080/', // emulador Android aponta para localhost
  );
}