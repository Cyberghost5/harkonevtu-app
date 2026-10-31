class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://tincitybill.com/api/v1',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '62911045279-eoc6g6ck4qufdr1jqlvjhjbngk0rnpmt.apps.googleusercontent.com',
  );
}
