part of 'library.dart';

class BindingStatePolling {
  static const String _tag = "BindingStatePolling";
  static const int errorTimeout = -1;
  static const int _pollingDuration = 90;
  static const int _pollingInterval = 5;

  OnResponseListener<String>? _onResponseListener;
  final String _bindingToken;
  Timer? _timer;
  int _elapsedTime = 0;
  bool _started = false;
  int lastestErrorCode = errorTimeout;
  String lastestErrorMessage = "timeout";

  BindingStatePolling._(this._bindingToken);

  set listener(OnResponseListener<String> listener) => _onResponseListener = listener;

  void start() async {
    if (_started) {
      Logging.e(_tag, "[start] Already started.");
      return;
    }

    Logging.i(_tag, "[start] ...");

    _started = true;
    _elapsedTime = 0;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: _pollingInterval), (Timer timer) async {
      _elapsedTime += _pollingInterval;

      if (_elapsedTime >= _pollingDuration) {
        Logging.e(_tag, "[timeout] $lastestErrorCode, $lastestErrorMessage");
        timer.cancel();
        _onResponseListener?.call(Resp.error(lastestErrorCode, lastestErrorMessage));
      } else {
        await _checkBindingStatus();
      }
    });

    Logging.i(_tag, "[start] Done.");
  }

  void stop() async {
    if (!_started) {
      Logging.e(_tag, "[stop] Not started.");
      return;
    }
    _started = false;
    _timer?.cancel();

    Logging.i(_tag, "[stop] Done.");
  }

  Future<void> _checkBindingStatus() async {
    Logging.i(_tag, "[_checkBindingStatus] ...");
    final statusResp = await BindingService.status(_bindingToken);
    if (statusResp.success) {
      final deviceId = statusResp.data?.deviceId ?? "";
      Logging.i(_tag, "[_checkBindingStatus] success, deviceId: $deviceId");
      if (deviceId.isNotEmpty) {
        stop();
        _onResponseListener?.call(Resp.success(deviceId));
      }
    } else {
      lastestErrorCode = statusResp.code ?? errorTimeout;
      lastestErrorMessage = statusResp.message ?? "Unknown Error";
      Logging.e(_tag, "[_checkBindingStatus] error: $lastestErrorCode, message: $lastestErrorMessage");
    }
  }

  static BindingStatePolling create(String bindingToken) => BindingStatePolling._(bindingToken);
}
