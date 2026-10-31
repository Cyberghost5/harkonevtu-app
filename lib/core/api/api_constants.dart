class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://tincitybill.com/api/v1',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '551390537530-56gnh69bubag54cg6s35c5tqir4nvpho.apps.googleusercontent.com',
  );
}
