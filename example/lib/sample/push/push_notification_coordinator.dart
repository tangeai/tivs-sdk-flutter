import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rapid_kit/rapid_kit.dart';

import '../channel/rapid_kit_sample_channel.dart';

class PushRegistration {
  const PushRegistration({
    required this.token,
    required this.channel,
    required this.isTest,
  });

  final String token;
  final PushChannel channel;
  final bool isTest;

  static PushRegistration? fromMap(Map<dynamic, dynamic>? value) {
    if (value == null) return null;
    final token = value['token'];
    final channel = value['channel'];
    final isTest = value['isTest'];
    if (token is! String || token.isEmpty || channel is! String) return null;

    final matchedChannel = PushChannel.values.cast<PushChannel?>().firstWhere(
          (item) => item?.value == channel,
          orElse: () => null,
        );
    if (matchedChannel == null) return null;
    return PushRegistration(
      token: token,
      channel: matchedChannel,
      isTest: isTest is bool ? isTest : false,
    );
  }
}

class PushNotificationCoordinator {
  PushNotificationCoordinator._();

  static final PushNotificationCoordinator instance =
      PushNotificationCoordinator._();

  PushRegistration? _registration;
  StreamSubscription<dynamic>? _eventSubscription;
  bool _initialized = false;
  bool _isAuthenticated = false;
  bool _associationSucceeded = false;
  int _sessionVersion = 0;
  Object? _bindingRequestID;

  Future<void> initialize() async {
    if (_initialized || !Platform.isIOS) return;
    _initialized = true;
    _eventSubscription = NotificationChannel.events.listen(_handleEvent);
    final registration = PushRegistration.fromMap(
      await NotificationChannel.getPushRegistration(),
    );
    if (registration != null) _handleRegistration(registration);
  }

  void handleAuthenticationSucceeded() {
    _sessionVersion++;
    _isAuthenticated = true;
    _associationSucceeded = false;
    _bindingRequestID = null;
    unawaited(_tryAssociate());
  }

  void handleAuthenticationInvalidated() {
    _sessionVersion++;
    _isAuthenticated = false;
    _associationSucceeded = false;
    _bindingRequestID = null;
  }

  void _handleEvent(dynamic event) {
    if (event is! Map || event['type'] != 'registration') return;
    final registration = PushRegistration.fromMap(
      event['registration'] as Map<dynamic, dynamic>?,
    );
    if (registration != null) _handleRegistration(registration);
  }

  void _handleRegistration(PushRegistration registration) {
    if (_registration?.token != registration.token ||
        _registration?.channel != registration.channel ||
        _registration?.isTest != registration.isTest) {
      _registration = registration;
      _associationSucceeded = false;
      _bindingRequestID = null;
    }
    unawaited(_tryAssociate());
  }

  Future<void> _tryAssociate() async {
    final registration = _registration;
    if (registration == null ||
        !_isAuthenticated ||
        _associationSucceeded ||
        _bindingRequestID != null) {
      return;
    }

    final requestID = Object();
    final requestSessionVersion = _sessionVersion;
    _bindingRequestID = requestID;

    try {
      final result = await PushNotificationService.associate(
        registration.token,
        registration.channel,
        isTest: registration.isTest,
      );

      if (!_requestIsCurrent(requestID, requestSessionVersion)) return;

      _bindingRequestID = null;
      _associationSucceeded = result.success;
      debugPrint(
        '[PushNotificationCoordinator] association completed, '
        'success=${result.success}, code=${result.code}',
      );
    } catch (error) {
      if (!_requestIsCurrent(requestID, requestSessionVersion)) return;
      _bindingRequestID = null;
      _associationSucceeded = false;
      debugPrint(
        '[PushNotificationCoordinator] association failed, error=$error',
      );
    }
  }

  bool _requestIsCurrent(Object requestID, int requestSessionVersion) {
    return _sessionVersion == requestSessionVersion &&
        identical(_bindingRequestID, requestID) &&
        _isAuthenticated;
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _initialized = false;
  }
}
