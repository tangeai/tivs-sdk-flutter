part of '../library.dart';

class ConnectedCall {
  final _CallRuntime _runtime;

  ConnectedCall._(this._runtime);

  String get deviceId => _runtime.deviceId;
  ConnectedCallState get state => _runtime.currentConnectedCallState;
  CallEndReason? get endReason => _runtime.currentConnectedCallEndReason;
  bool get isTerminal =>
      state == ConnectedCallState.ended || state == ConnectedCallState.failed;
  Pipe get pipe => _runtime.pipe!;

  void addListener(ConnectedCallEventListener listener) {
    _runtime.addConnectedCallListener(listener);
  }

  void removeListener(ConnectedCallEventListener listener) {
    _runtime.removeConnectedCallListener(listener);
  }

  void bindLiveStream(LiveStream? stream) {
    _runtime.bindLiveStream(stream);
  }

  Future<Ret> hangup() => _runtime.hangupConnectedCall();
}
