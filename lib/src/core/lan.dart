part of 'library.dart';

typedef OnLanDiscoveryRefreshListener = void Function(List<String>);
typedef OnLanDiscoveryTimeoutListener = void Function();

class LanDiscovery {
  static const String _tag = 'LanDiscovery';
  static const String _defaultBroadcastAddress = '255.255.255.255';
  static const int _discoveryDuration = 60;
  static const int _discoveryInterval = 1;
  static const int _broadcastRefreshInterval = 3;

  final Future<String> Function()? _loadBroadcastAddress;
  final void Function(String) _configureBroadcastAddress;
  final RapidNativeLanScan Function() _createScanner;
  final void Function(String) _log;
  final List<String> _devices = [];
  int previousDeviceCount = 0;

  RapidNativeLanScan? _nativeLanScan;

  Timer? _timer;
  bool _started = false;
  int _startGeneration = 0;
  bool _addressLookupInProgress = false;
  String? _broadcastAddress;

  OnLanDiscoveryRefreshListener? _onRefresh;
  OnLanDiscoveryTimeoutListener? _onTimeout;

  LanDiscovery()
      : _loadBroadcastAddress = Platform.isIOS
            ? (() => _PlatformChannel.localNetworkBroadcastAddress(
                logDetails: false))
            : null,
        _configureBroadcastAddress =
            rapidNativeConfigureLocalNetworkBroadcastAddress,
        _createScanner = RapidNativeLanScan.new,
        _log = ((message) => Logging.i(_tag, message));

  @visibleForTesting
  LanDiscovery.forTesting({
    Future<String> Function()? loadBroadcastAddress,
    required void Function(String) configureBroadcastAddress,
    required RapidNativeLanScan Function() createScanner,
    required void Function(String) log,
  })  : _loadBroadcastAddress = loadBroadcastAddress,
        _configureBroadcastAddress = configureBroadcastAddress,
        _createScanner = createScanner,
        _log = log;

  set onRefresh(OnLanDiscoveryRefreshListener listener) =>
      _onRefresh = listener;
  set onTimeout(OnLanDiscoveryTimeoutListener listener) =>
      _onTimeout = listener;

  void start() {
    if (_started) return;
    _started = true;
    _timer?.cancel();
    _timer = null;
    _broadcastAddress = null;
    _devices.clear();
    previousDeviceCount = 0;

    _nativeLanScan?.stop();
    final generation = ++_startGeneration;
    if (_loadBroadcastAddress != null) {
      unawaited(_updateIOSBroadcastAddress(generation));
      return;
    }
    _startScanner(generation);
  }

  Future<void> _updateIOSBroadcastAddress(int generation) async {
    _addressLookupInProgress = true;
    var address = _defaultBroadcastAddress;
    String? failure;
    try {
      try {
        final discoveredAddress = await _loadBroadcastAddress!();
        final parsedAddress = InternetAddress.tryParse(discoveredAddress);
        if (parsedAddress?.type == InternetAddressType.IPv4 &&
            discoveredAddress != '0.0.0.0') {
          address = discoveredAddress;
        } else {
          failure = 'invalid broadcast address=$discoveredAddress';
        }
      } catch (error) {
        failure = 'broadcast lookup failed: $error';
      }
      if (!_started || generation != _startGeneration) return;
      if (address == _broadcastAddress) return;
      if (failure != null) _log('[start] $failure, fallback=$address');
      final replacingScanner = _broadcastAddress != null;
      _nativeLanScan?.stop();
      _devices.clear();
      previousDeviceCount = 0;
      _broadcastAddress = address;
      _log('[start] configuring broadcast address=$address');
      _configureBroadcastAddress(address);
      _startScanner(generation);
      if (replacingScanner) _onRefresh?.call([]);
    } finally {
      if (generation == _startGeneration) _addressLookupInProgress = false;
    }
  }

  void _startScanner(int generation) {
    _nativeLanScan = _createScanner();
    _nativeLanScan?.start();

    _timer ??= Timer.periodic(const Duration(seconds: _discoveryInterval),
        (Timer timer) {
      if (!_started || generation != _startGeneration) return;
      final elapsedTime = timer.tick * _discoveryInterval;
      if (elapsedTime >= _discoveryDuration) {
        final onTimeout = _devices.isEmpty ? _onTimeout : null;
        stop();
        onTimeout?.call();
        return;
      }

      final fullDevices = _nativeLanScan?.foundDevices() ?? [];
      if (fullDevices.length != previousDeviceCount) {
        previousDeviceCount = fullDevices.length;
        _devices.clear();
        for (var device in fullDevices) {
          _devices.add(device);
        }
        _onRefresh?.call(_devices);
      }
      if (!_started || generation != _startGeneration) return;
      if (_loadBroadcastAddress != null &&
          !_addressLookupInProgress &&
          elapsedTime % _broadcastRefreshInterval == 0) {
        unawaited(_updateIOSBroadcastAddress(generation));
      }
    });
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _startGeneration++;
    _addressLookupInProgress = false;
    _timer?.cancel();
    _timer = null;
    _devices.clear();
    previousDeviceCount = 0;
    _nativeLanScan?.stop();
    _nativeLanScan = null;
  }
}
