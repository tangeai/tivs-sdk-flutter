part of '../library.dart';

class OutgoingCall {
  final _CallRuntime _runtime;

  OutgoingCall._(this._runtime);

  static Future<OutgoingCall> start(
    String deviceId, {
    OutgoingCallOptions options = const OutgoingCallOptions(),
  }) async {
    _CallRegistry.ensureInitialized();

    final existing = _CallRegistry.runtimeOf(deviceId);
    if (existing != null && !existing.isTerminal) {
      throw StateError('call already exists: $deviceId');
    }

    final runtime = _CallRuntime.outgoing(
      deviceId: deviceId,
      outgoingOptions: options,
    );
    _CallRegistry.register(runtime);
    try {
      await runtime.prepareOutgoing();
    } catch (_) {
      _CallRegistry.unbind(runtime);
      rethrow;
    }
    unawaited(runtime.continueOutgoing());
    return runtime.outgoingCall!;
  }

  String get deviceId => _runtime.deviceId;
  OutgoingCallState get state => _runtime.currentOutgoingState;
  CallEndReason? get endReason => _runtime.currentOutgoingEndReason;
  bool get isTerminal =>
      state == OutgoingCallState.ended || state == OutgoingCallState.failed;
  Future<ConnectedCall> get connectedCall => _runtime.waitConnectedCall();

  void addListener(OutgoingCallEventListener listener) {
    _runtime.addOutgoingListener(listener);
  }

  void removeListener(OutgoingCallEventListener listener) {
    _runtime.removeOutgoingListener(listener);
  }

  Future<Ret> cancel() => _runtime.cancelOutgoing();
}
