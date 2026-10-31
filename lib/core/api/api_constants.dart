class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://nmilleniumresource.com.ng/api/v1',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '686309797782-j1176klhi6r422jgcoe4p6mjf2teef1c.apps.googleusercontent.com',
  );
}
