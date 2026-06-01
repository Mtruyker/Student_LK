import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Service for monitoring network connectivity status
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._() {
    _init();
  }

  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool _hasBeenOffline = false;
  DateTime? _lastConnectedAt;
  DateTime? _lastDisconnectedAt;

  /// Whether the device is currently connected to the internet
  bool get isConnected => _isConnected;

  /// Whether the device has been offline during this session
  bool get hasBeenOffline => _hasBeenOffline;

  /// When the device was last connected (null if never disconnected)
  DateTime? get lastConnectedAt => _lastConnectedAt;

  /// When the device was last disconnected (null if never disconnected)
  DateTime? get lastDisconnectedAt => _lastDisconnectedAt;

  /// Duration since last connection (null if currently connected)
  Duration? get timeSinceLastConnection {
    if (_isConnected || _lastDisconnectedAt == null) return null;
    return DateTime.now().difference(_lastDisconnectedAt!);
  }

  Future<void> _init() async {
    // Check initial connectivity
    await _updateConnectivityStatus();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        if (kDebugMode) {
          print('Connectivity error: $error');
        }
      },
    );
  }

  Future<void> _updateConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onConnectivityChanged(results);
    } catch (error) {
      if (kDebugMode) {
        print('Failed to check connectivity: $error');
      }
      // Assume connected if we can't check
      _updateConnectionState(true);
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
      result != ConnectivityResult.none
    );
    _updateConnectionState(hasConnection);
  }

  void _updateConnectionState(bool isConnected) {
    final wasConnected = _isConnected;
    _isConnected = isConnected;

    if (wasConnected != isConnected) {
      final now = DateTime.now();

      if (isConnected) {
        // Just came back online
        _lastConnectedAt = now;
        if (kDebugMode) {
          print('Device came back online');
        }
      } else {
        // Just went offline
        _lastDisconnectedAt = now;
        _hasBeenOffline = true;
        if (kDebugMode) {
          print('Device went offline');
        }
      }

      notifyListeners();
    }
  }

  /// Manually check connectivity (useful for testing)
  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
    return _isConnected;
  }

  /// Reset the offline tracking (useful after successful sync)
  void resetOfflineTracking() {
    _hasBeenOffline = false;
    _lastDisconnectedAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Mixin for widgets that need to react to connectivity changes
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  late ConnectivityService _connectivityService;
  bool get isConnected => _connectivityService.isConnected;
  bool get hasBeenOffline => _connectivityService.hasBeenOffline;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService.instance;
    _connectivityService.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      onConnectivityChanged(_connectivityService.isConnected);
    }
  }

  /// Override this method to handle connectivity changes
  void onConnectivityChanged(bool isConnected) {
    // Default implementation - override in your widget
    setState(() {});
  }
}