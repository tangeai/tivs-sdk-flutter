part of 'library.dart';

class FirmwareStatePolling {
  static const int errorTimeout = -1;
  static const String _tag = "FirmwareStatePolling";
  static const int _defaultPollingDuration = 60 * 3;
  static const int _pollingInterval = 10;
  static const int kMaxTotalDuration = 60 * 30;

  final String _deviceId;
  final String _targetVersion;

  OnResultListener? _onResultListener;
  void Function(int)? _on_progress;
  Timer? _timer;
  int _elapsedTime = 0;
  int _phase_started_at = 0;
  int _last_progress = -1;
  bool _request_in_flight = false;
  bool _started = false;
  int lastestErrorCode = errorTimeout;
  String lastestErrorMessage = "timeout";

  int _pollingDuration = _defaultPollingDuration;

  FirmwareStatePolling._(this._deviceId, this._targetVersion);

  set listener(OnResultListener listener) => _onResultListener = listener;

  set progress_listener(void Function(int)? listener) => _on_progress = listener;

  /// Timeout in seconds for download inactivity and for the upgrade result after download.
  set pollingDuration(int duration) {
    if (duration < 60) throw ArgumentError("pollingDuration must be greater than 60");
    _pollingDuration = duration;
  }

  void start() async {
    if (_started) return;

    _started = true;
    _elapsedTime = 0;
    _phase_started_at = 0;
    _last_progress = -1;
    _request_in_flight = false;
    lastestErrorCode = errorTimeout;
    lastestErrorMessage = "timeout";
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: _pollingInterval), (Timer timer) async {
      _elapsedTime = timer.tick * _pollingInterval;

      if (_elapsedTime >= kMaxTotalDuration || _elapsedTime - _phase_started_at >= _pollingDuration) {
        lastestErrorCode = errorTimeout;
        lastestErrorMessage = _last_progress == 100 ? "Upgrade result timeout" : "Firmware download timeout";
        stop();
        _onResultListener?.call(Ret.error(lastestErrorCode, lastestErrorMessage));
      } else if (!_request_in_flight) {
        await _checkBindingStatus(timer);
      }
    });
  }

  void stop() {
    if (!_started) return;

    _started = false;
    _timer?.cancel();
  }

  Future<void> _checkBindingStatus(Timer timer) async {
    _request_in_flight = true;
    try {
      final statusResp = await FirmwareService.query_upgrade_status_for_version(_deviceId, _targetVersion);
      if (!_started || _timer != timer) return;
      if (!statusResp.success) {
        lastestErrorCode = statusResp.code ?? errorTimeout;
        lastestErrorMessage = statusResp.message ?? "Unknown Error";
        return;
      }
      final progress = statusResp.data?.progress;
      if (progress != null && progress >= 0 && progress <= 100 && progress > _last_progress) {
        _last_progress = progress;
        _phase_started_at = timer.tick * _pollingInterval;
      }
      if (progress != null) _on_progress?.call(progress);
      if (!_started || _timer != timer) return;
      if (statusResp.data?.status == 1) {
        stop();
        _onResultListener?.call(Ret.error(1, statusResp.data?.description ?? "Firmware upgrade failed"));
        return;
      }
      if (statusResp.data?.status == 2 && statusResp.data?.currentVersion == _targetVersion) {
        stop();
        _onResultListener?.call(Ret.success());
      }
    } catch (error) {
      if (!_started || _timer != timer) return;
      lastestErrorCode = errorTimeout;
      lastestErrorMessage = error.toString();
    } finally {
      if (_timer == timer) _request_in_flight = false;
    }
  }

  static FirmwareStatePolling create(String deviceId, String targetVersion) => FirmwareStatePolling._(deviceId, targetVersion);
}
