part of '../library.dart';

class CallObserver {
  static final List<IncomingCallListener> _incomingListeners = [];

  static void addIncomingListener(IncomingCallListener listener) {
    _CallRegistry.ensureInitialized();
    if (_incomingListeners.contains(listener)) {
      return;
    }
    _incomingListeners.add(listener);
  }

  static void removeIncomingListener(IncomingCallListener listener) {
    _incomingListeners.remove(listener);
  }

  static void _emitIncoming(IncomingCall call) {
    final listeners = List<IncomingCallListener>.from(_incomingListeners);
    for (final listener in listeners) {
      listener(call);
    }
  }
}
