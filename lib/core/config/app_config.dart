class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // defaultValue: 'https://app-production-647c.up.railway.app/', // emulador Android aponta para localhost
  );
}