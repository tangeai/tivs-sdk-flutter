part of 'library.dart';

class AccessPointTransport {
  static const String _tag = "AccessPointTransport";
  static const int errorTimeout = 1;
  static const int errorUserInvalid = 2;
  static const int errorNotPrepared = 3;
  static const int errorSentError = 4;
  static const int _codeSuccess = 0;

  final RapidNativeProfileTransmitter _nativeProfileTransmitter;
  OnResultListener? _onResultListener;
  bool _prepared = false;
  AccessPointTransport._(this._nativeProfileTransmitter);

  set listener(OnResultListener func) => _onResultListener = func;

  void prepare(String ssid, String password, String bindingToken) async {
    Logging.i(_tag, "[prepare] ssid: $ssid, password: $password, bindingToken: $bindingToken");
    if (ssid.isNotEmpty && bindingToken.isNotEmpty) _prepared = true;
    _nativeProfileTransmitter.prepare(ssid, password, bindingToken);
  }

  void start() async {
    if (!_prepared) {
      Logging.e(_tag, "[start] Not prepared.");
      _onResultListener?.call(Ret.error(errorNotPrepared, "Not prepared."));
      return;
    }

    Logging.i(_tag, "[start] ...");

    _nativeProfileTransmitter.listener = (state) {
      Logging.i(_tag, "[on_native_state] $state");
      switch (state) {
        case _codeSuccess:
          _onResultListener?.call(Ret.success());
          _PlatformChannel.releaseTransportWiFi();
          break;
        default:
          _onResultListener?.call(Ret.error(state, "error while sending profile."));
          _PlatformChannel.releaseTransportWiFi();
          break;
      }
    };

    if (Platform.isIOS) {
      Logging.i(_tag, "[start] try to get local network broadcast address ...");

      final address = await _PlatformChannel.localNetworkBroadcastAddress();
      Logging.i(_tag, "[start] localNetworkBroadcastAddress: $address");

      if (address.isNotEmpty && address != "0.0.0.0") {
        rapidNativeConfigureLocalNetworkBroadcastAddress(address);
      } else {
        Logging.e(_tag, "[start] localNetworkBroadcastAddress is invalid: $address");
        _onResultListener?.call(Ret.error(errorNotPrepared, "localNetworkBroadcastAddress is invalid: $address"));
        return;
      }
    }

    Logging.i(_tag, "[start] try to ensure transport by wifi ...");

    final ensureTransportByWifiResult = await _PlatformChannel.ensureTransportByWifi();
    Logging.i(_tag, "[start] ensureTransportByWifi: $ensureTransportByWifiResult");

    _nativeProfileTransmitter.start();

    Logging.i(_tag, "[start] Done.");
  }

  void stop() {
    Logging.i(_tag, "[stop]");
    _PlatformChannel.releaseTransportWiFi();
    _nativeProfileTransmitter.stop();
  }

  void destroy() {
    Logging.i(_tag, "[destroy]");
    _nativeProfileTransmitter.destroy();
  }

  static AccessPointTransport create() {
    Logging.i(_tag, "[create]");
    final nativeProfileTransmitter = RapidNativeProfileTransmitter();
    nativeProfileTransmitter.create();
    return AccessPointTransport._(nativeProfileTransmitter);
  }
}
