part of 'library.dart';

typedef PersistentChannelStateCallback = void Function(PersistentChannelState state);
typedef PersistentChannelMessageCallback = void Function(String name, String detail);

enum PersistentChannelState { disconnected, connecting, connected }

class PersistentChannel {
  static final List<PersistentChannelStateCallback> _stateListeners = [];
  static final List<PersistentChannelMessageCallback> _messageListeners = [];
  static bool _isCallbackSet = false;

  static void connect() {
    if (!_isCallbackSet) {
      RapidNativePersistentChannel.instance.setStateCallback(_onStateChanged);
      RapidNativePersistentChannel.instance.setMessageCallback(_onMessageReceived);
      _isCallbackSet = true;
    }
    RapidNativePersistentChannel.instance.connect();
  }

  static void disconnect() => RapidNativePersistentChannel.instance.disconnect();

  static int currentState() => RapidNativePersistentChannel.instance.currentState();

  static PersistentChannelState currentStateEnum() {
    final state = currentState();
    return state >= 0 && state < PersistentChannelState.values.length ? PersistentChannelState.values[state] : PersistentChannelState.disconnected;
  }

  static bool isConnected() => currentStateEnum() == PersistentChannelState.connected;

  static void addStateListener(PersistentChannelStateCallback callback) {
    if (!_stateListeners.contains(callback)) _stateListeners.add(callback);
  }

  static void removeStateListener(PersistentChannelStateCallback callback) => _stateListeners.remove(callback);

  static void addMessageListener(PersistentChannelMessageCallback callback) {
    if (!_messageListeners.contains(callback)) _messageListeners.add(callback);
  }

  static void removeMessageListener(PersistentChannelMessageCallback callback) => _messageListeners.remove(callback);

  static void cleanup() {
    disconnect();
    _stateListeners.clear();
    _messageListeners.clear();
    _isCallbackSet = false;
  }

  static void _onStateChanged(int state, String reason) {
    final stateEnum =
        state >= 0 && state < PersistentChannelState.values.length ? PersistentChannelState.values[state] : PersistentChannelState.disconnected;
    for (final callback in _stateListeners) {
      callback(stateEnum);
    }
  }

  static void _onMessageReceived(String name, String detail) {
    for (final callback in _messageListeners) {
      callback(name, detail);
    }
  }
}
