part of 'library.dart';

class LiveStream {
  static const String _tag = 'LiveStream';
  final RapidNativeLiveStream _nativeLiveStream;
  final String _kind;
  late final int _instanceId = identityHashCode(this);

  bool _started = false;

  LiveStream._(this._nativeLiveStream, this._kind) {
    Logging.i(_tag, '[$_logPrefix][create] caller=${rapidStackTrace()}');
  }

  String get _logPrefix => 'stream#$_instanceId kind=$_kind';

  void start() {
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      '[$_logPrefix][start.begin] started=$_started caller=${rapidStackTrace()}',
    );
    _nativeLiveStream.start();
    _started = true;
    stopwatch.stop();
    Logging.i(
      _tag,
      '[$_logPrefix][start.end] execution=${stopwatch.elapsedMilliseconds}ms metrics=${metricsSnapshot()} firstPacket=${firstPacketMetricsSnapshot()}',
    );
  }

  void stop() {
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      '[$_logPrefix][stop.begin] started=$_started metrics=${metricsSnapshot()} firstPacket=${firstPacketMetricsSnapshot()} caller=${rapidStackTrace()}',
    );
    _nativeLiveStream.stop();
    _started = false;
    stopwatch.stop();
    Logging.i(
      _tag,
      '[$_logPrefix][stop.end] execution=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  void destroy() {
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      '[$_logPrefix][destroy.begin] started=$_started metrics=${metricsSnapshot()} firstPacket=${firstPacketMetricsSnapshot()} caller=${rapidStackTrace()}',
    );
    if (_started) {
      Logging.i(
        _tag,
        '[$_logPrefix][destroy] live stream is started, should stop it first',
      );
      if (kDebugMode) {
        throw FlutterError(
          'LiveStream.destroy() called - you MUST call stop() first!',
        );
      }
    }
    _nativeLiveStream.destroy();
    stopwatch.stop();
    Logging.i(
      _tag,
      '[$_logPrefix][destroy.end] execution=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  Pointer<Void>? provider({int cameraIndex = 0}) =>
      _nativeLiveStream.indexedProvider(cameraIndex);
  void switchQuality(int quality) => _nativeLiveStream.switchQuality(quality);
  void highQuality() => _nativeLiveStream.highQuality();
  void lowQuality() => _nativeLiveStream.lowQuality();
  int currentQuality() => _nativeLiveStream.currentQuality();
  void requireKeyFrame() => _nativeLiveStream.requireKeyFrame();
  void setExternalDataListener(RapidExternalDataListener? listener) =>
      _nativeLiveStream.setExternalDataListener(listener);
  // ignore: non_constant_identifier_names
  String? receive_metrics({int cameraIndex = 0}) =>
      _nativeLiveStream.receive_metrics(cameraIndex: cameraIndex);
  String? metricsSnapshot({int cameraIndex = 0}) =>
      _nativeLiveStream.metricsSnapshot(cameraIndex: cameraIndex);
  String? firstPacketMetricsSnapshot({int cameraIndex = 0}) =>
      _nativeLiveStream.firstPacketMetricsSnapshot(cameraIndex: cameraIndex);

  static LiveStream createPrimary(Pipe pipe, {bool enableAudio = true}) {
    final nativeLiveStream = RapidNativeLiveStream(pipe._nativePipe);
    nativeLiveStream.createPrimary(enableAudio: enableAudio);
    return LiveStream._(nativeLiveStream, 'primary');
  }

  static LiveStream createSecondary(Pipe pipe, {bool enableAudio = false}) {
    final nativeLiveStream = RapidNativeLiveStream(pipe._nativePipe);
    nativeLiveStream.createSecondary(enableAudio: enableAudio);
    return LiveStream._(nativeLiveStream, 'secondary');
  }
}
