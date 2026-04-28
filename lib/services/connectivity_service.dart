import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Stream controller for connectivity changes
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  // Current connectivity status
  bool _isConnected = true;
  
  // Getters
  bool get isConnected => _isConnected;
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('Connectivity error: $error');
        _updateConnectivity(false);
      },
    );
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      final bool isConnected = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );
      _updateConnectivity(isConnected);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateConnectivity(false);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final bool isConnected = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    _updateConnectivity(isConnected);
  }

  /// Update connectivity status and notify listeners
  void _updateConnectivity(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectivityController.add(_isConnected);
      debugPrint('Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}