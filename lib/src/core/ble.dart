part of 'library.dart';

class BleDevice {
  final String name;
  final String id;

  BleDevice(this.name, this.id);
}

class BleAbility {
  static Future<bool> enabled() async => _PlatformChannel.isBluetoothEnabled();
  static Future<bool> permissionGranted() async => _PlatformChannel.isBluetoothPermissionGranted();
  static Future<void> acquirePermission() async => _PlatformChannel.acquireBluetoothPermission();
  static Future<void> _startSearch() async => _PlatformChannel.startBluetoothDiscovery();
  static Future<void> _stopSearch() async => _PlatformChannel.stopBluetoothDiscovery();
  static Future<bool> _connect(String mac, List<String>? characteristics) async => _PlatformChannel.connectBluetoothDevice(mac, characteristics);
  static Future<void> _disconnect(String mac) async => _PlatformChannel.disconnectBluetoothDevice(mac);
  static Future<bool> _write(Uint8List data) async => _PlatformChannel.writeBluetoothData(data);
  static Future<List<BleDevice>> _nearbyDevices() async => (await _PlatformChannel.getBluetoothDevices())
      .where((device) => (device['name'] ?? '').isNotEmpty && (device['address'] ?? '').isNotEmpty)
      .map((device) => BleDevice(device['name']!, device['address']!))
      .toList();
}

typedef OnBleDiscoveryRefreshListener = void Function(List<BleDevice>);
typedef OnBleDiscoveryTimeoutListener = void Function();

abstract class BleDeviceFilter {
  bool accept(String name);
}

class DefaultBleDeviceFilter implements BleDeviceFilter {
  @override
  bool accept(String name) => name.startsWith("AICAM_");
}

class BleDiscovery {
  static const String _tag = "BleDiscovery";
  static const int _discoveryDuration = 90;
  static const int _discoveryInterval = 1;

  final List<BleDevice> _devices = [];
  String _previousDeviceSignature = '';

  Timer? _timer;
  int _elapsedTime = 0;
  bool _started = false;

  OnBleDiscoveryRefreshListener? _onRefresh;
  OnBleDiscoveryTimeoutListener? _onTimeout;
  BleDeviceFilter _filter = DefaultBleDeviceFilter();

  set filter(BleDeviceFilter filter) => _filter = filter;
  set onRefresh(OnBleDiscoveryRefreshListener listener) => _onRefresh = listener;
  set onTimeout(OnBleDiscoveryTimeoutListener listener) => _onTimeout = listener;
  void start() {
    if (_started) {
      Logging.e(_tag, "[start] Already started.");
      return;
    }

    Logging.i(_tag, "[start] ...");

    _started = true;
    _elapsedTime = 0;
    _timer?.cancel();
    _devices.clear();
    _previousDeviceSignature = '';

    BleAbility._startSearch();

    _timer = Timer.periodic(const Duration(seconds: _discoveryInterval), (Timer timer) async {
      _elapsedTime += _discoveryInterval;
      if (_elapsedTime >= _discoveryDuration) {
        Logging.i(_tag, "[timeout]");
        if (_devices.isEmpty) _onTimeout?.call();
        stop();
        return;
      }

      final fullDevices = await BleAbility._nearbyDevices();
      final deviceSignature = _deviceSignature(fullDevices);
      if (deviceSignature != _previousDeviceSignature) {
        _previousDeviceSignature = deviceSignature;
        _devices.clear();
        Logging.i(_tag, "[refresh] ${fullDevices.length} devices found.");
        for (var device in fullDevices) {
          Logging.i(_tag, "[refresh]   |__ ${device.name} - (${device.id})");
          if (_filter.accept(device.name)) _devices.add(device);
        }
        _onRefresh?.call(_devices);
      }
    });

    Logging.i(_tag, "[start] Done.");
  }

  String _deviceSignature(List<BleDevice> devices) {
    final entries = devices.map((device) => '${device.id}:${device.name}').toList()..sort();
    return entries.join('|');
  }

  void stop() {
    if (!_started) {
      Logging.e(_tag, "[stop] Not started.");
      return;
    }

    Logging.i(_tag, "[stop] ...");

    _started = false;
    _timer?.cancel();
    _devices.clear();
    _previousDeviceSignature = '';

    BleAbility._stopSearch();

    Logging.i(_tag, "[stop] Done.");
  }
}

class BleTransport {
  static const int errorNotPrepared = -1;
  static const int errorConnectTimeout = -2;
  static const int errorSentTimeout = -3;

  List<String>? _characteristicsUUIDs;

  static const String _tag = "BleTransport";

  final String _mac;
  OnResultListener? _onResultListener;
  bool _started = false;
  bool _prepared = false;
  bool _connected = false;
  bool _sent = false;
  Uint8List? _bindingProfile;

  BleTransport(this._mac);

  set characteristics(List<String> characteristics) => _characteristicsUUIDs = characteristics;
  set listener(OnResultListener func) => _onResultListener = func;
  void prepare(String ssid, String password, String bindingToken) async {
    Logging.i(_tag, "[prepare] ssid: $ssid, password: $password, bindingToken: $bindingToken");
    if (ssid.isNotEmpty && bindingToken.isNotEmpty) _prepared = true;
    _bindingProfile = rapidNativeCreateBindingProfileWithHeader(ssid, password, bindingToken);
    Logging.i(_tag, "[prepare] binding profile ready, length: ${_bindingProfile?.length}");
  }

  void start() async {
    if (_started) {
      Logging.e(_tag, "[start] Already started.");
      return;
    }

    if (!_prepared) {
      Logging.e(_tag, "[start] Not prepared.");
      _onResultListener?.call(Ret.error(errorNotPrepared, "binding profile not ready."));
      return;
    }

    _started = true;

    _connect();

    Logging.i(_tag, "[start] Done.");
  }

  void stop() async {
    if (!_started) {
      Logging.e(_tag, "[stop] Not started.");
      return;
    }

    Logging.i(_tag, "[stop] ...");

    _started = false;
    _connected = false;
    _sent = false;
    _bindingProfile = null;
    await BleAbility._disconnect(_mac);

    Logging.i(_tag, "[stop] Done.");
  }

  void _connect() async {
    if (!_started) return;
    Logging.i(_tag, "[connect] ...");
    final connected = await BleAbility._connect(_mac, _characteristicsUUIDs);
    if (!_started) {
      Logging.i(_tag, "[connect] Canceled.");
      return;
    }

    Logging.i(_tag, "[connect] connected: $connected");

    if (!connected) {
      _onResultListener?.call(Ret.error(errorConnectTimeout, "Connect timeout."));
      return;
    }

    _connected = true;
    _write();
  }

  void _write() async {
    if (!_started) {
      Logging.e(_tag, "[write] Not started.");
      return;
    }
    if (!_connected) {
      Logging.e(_tag, "[write] Not connected.");
      _onResultListener?.call(Ret.error(errorConnectTimeout, "Not connected."));
      return;
    }

    if (_bindingProfile == null) {
      Logging.e(_tag, "[write] Not prepared.");
      _onResultListener?.call(Ret.error(errorNotPrepared, "binding profile not ready."));
      return;
    }

    Logging.i(_tag, "[write] ...");

    final sent = await BleAbility._write(_bindingProfile!);
    if (!_started) {
      Logging.i(_tag, "[write] Canceled.");
      return;
    }

    Logging.i(_tag, "[write] sent: $sent");

    if (sent) {
      _sent = true;
      _onResultListener?.call(Ret.success());
    } else {
      _onResultListener?.call(Ret.error(errorSentTimeout, "Sent timeout."));
    }
  }

  static BleTransport create(String id) => BleTransport(id);
}
