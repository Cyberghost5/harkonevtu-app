import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  ConnectivityService._internal() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final isConnected = await hasInternetConnection();
      _connectionController.add(isConnected);
    });
  }

  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
      // Socket lookup check for actual internet reachability
      final lookup = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
