part of 'library.dart';

class RapidNativePersistentChannel {
  static const String _tag = "NativePersistentChannel";

  static RapidNativePersistentChannel? _instance;
  static RapidNativePersistentChannel get instance => _instance ??= RapidNativePersistentChannel._();

  Function(int, String)? _stateCallback;
  Function(String, String)? _messageCallback;

  late final ReceivePort _receivePortOfState;
  late final SendPort _sendPortOfState;
  late final ReceivePort _receivePortOfMessage;
  late final SendPort _sendPortOfMessage;

  RapidNativePersistentChannel._() {
    _receivePortOfState = ReceivePort();
    _sendPortOfState = _receivePortOfState.sendPort;
    _receivePortOfMessage = ReceivePort();
    _sendPortOfMessage = _receivePortOfMessage.sendPort;

    _receivePortOfState.asBroadcastStream().listen((dynamic message) {
      if (message is int) _onStateChanged(message);
    });

    _receivePortOfMessage.asBroadcastStream().listen((dynamic message) {
      if (message is Uint8List) {
        _onMessageReceived(utf8.decode(message));
      }
    });
  }

  void setStateCallback(Function(int, String) callback) {
    _stateCallback = callback;
    coreApiPersistentBinding.RAPID_Core_PersistentChannel_SetStateSendPort(_sendPortOfState.nativePort);
  }

  void setMessageCallback(Function(String, String) callback) {
    _messageCallback = callback;
    coreApiPersistentBinding.RAPID_Core_PersistentChannel_SetMessageSendPort(_sendPortOfMessage.nativePort);
  }

  void connect() => coreApiPersistentBinding.RAPID_Core_PersistentChannel_Connect();
  void disconnect() => coreApiPersistentBinding.RAPID_Core_PersistentChannel_Disconnect();
  int currentState() => coreApiPersistentBinding.RAPID_Core_PersistentChannel_CurrentState();

  void _onStateChanged(int state) {
    Logging.i(_tag, "[_onStateChanged] state: $state");
    _stateCallback?.call(state, "");
  }

  void _onMessageReceived(String jsonString) {
    Logging.i(_tag, "[_onMessageReceived] jsonString: $jsonString");
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final String name = json['name'] ?? '';
    final String detail = json['detail'] ?? '';
    _messageCallback?.call(name, detail);
  }
}
