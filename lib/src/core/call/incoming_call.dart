part of '../library.dart';

class IncomingCall {
  final _CallRuntime _runtime;

  IncomingCall._(this._runtime);

  String get deviceId => _runtime.deviceId;
  IncomingCallState get state => _runtime.currentIncomingState;
  CallEndReason? get endReason => _runtime.currentIncomingEndReason;
  bool get isTerminal =>
      state == IncomingCallState.ended || state == IncomingCallState.failed;
  Future<ConnectedCall> get connectedCall => _runtime.waitConnectedCall();

  void addListener(IncomingCallEventListener listener) {
    _runtime.addIncomingListener(listener);
  }

  void removeListener(IncomingCallEventListener listener) {
    _runtime.removeIncomingListener(listener);
  }

  Future<Ret> accept() => _runtime.acceptIncoming();

  Future<Ret> reject() => _runtime.rejectIncoming();
}
