class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://dakeventures.com.ng/api/v1',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '660239500980-f9s9sgakcbbqaqf7d3i1o1tsmce6fo0d.apps.googleusercontent.com',
  );
}
