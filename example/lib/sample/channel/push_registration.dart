import 'dart:async';

import 'package:flutter/services.dart';

/// One registration per signed-in home page. A new login obtains a fresh token.
class PushRegistration {
  PushRegistration({
    required this.getToken,
    required this.associate,
    required this.log,
    required this.onFailure,
  });

  final Future<String> Function() getToken;
  final Future<void> Function(String token) associate;
  final void Function(String message) log;
  final void Function(String stage, String code) onFailure;

  static const _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 2),
  ];

  Timer? _retryTimer;
  String? _token;
  bool _running = false;
  bool _disposed = false;
  bool _registered = false;
  int _retries = 0;

  /// Retry on returning to home after the automatic retry budget is exhausted.
  void ensureRegistered() {
    if (_disposed || _registered || _running || _retryTimer != null) return;
    _retries = 0;
    unawaited(_register());
  }

  Future<void> _register() async {
    if (_disposed || _running) return;
    _running = true;
    var stage = 'get_token';
    try {
      log('stage=$stage attempt=${_retries + 1}');
      _token ??= await getToken();
      if (_disposed) return;
      stage = 'associate';
      log('stage=$stage channel=harmony');
      await associate(_token!);
      if (_disposed) return;
      _registered = true;
      log('stage=associate success channel=harmony');
    } catch (error) {
      if (_disposed) return;
      final code = error is PlatformException
          ? error.code
          : error.runtimeType.toString();
      // Do not include the token, HTTP body, or exception message in logs.
      log('stage=$stage failed code=$code');
      if (_retries < _retryDelays.length) {
        final delay = _retryDelays[_retries++];
        log('retry_in_seconds=${delay.inSeconds}');
        _retryTimer = Timer(delay, () {
          _retryTimer = null;
          unawaited(_register());
        });
      } else {
        onFailure(stage, code);
      }
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _token = null;
  }
}
