part of 'library.dart';

enum CloudReplaySpeed { x1, x2, x4, x8 }

enum CloudReplayMode { normal, timelapse }

enum CloudReplayDownloadStartResultType {
  success,
  networkError,
  noPermitted,
  invalidParameter,
  invalidResponse,
  fileTooLong
}

class CloudReplayDownloadStartResult {
  final CloudReplayDownloadStartResultType type;
  final int errorCode;
  final int requestedDurationSeconds;
  final int permittedDurationSeconds;

  const CloudReplayDownloadStartResult({
    required this.type,
    required this.errorCode,
    this.requestedDurationSeconds = 0,
    this.permittedDurationSeconds = 0,
  });

  bool get success => type == CloudReplayDownloadStartResultType.success;
  int get effectiveDurationSeconds =>
      requestedDurationSeconds < permittedDurationSeconds
          ? requestedDurationSeconds
          : permittedDurationSeconds;
}

typedef CloudReplayChunkNotFoundListener = void Function(int);
typedef CloudReplayCompleteListener = void Function();
typedef CloudReplayRetrieveErrorListener = void Function(int);

class CloudReplayStream {
  static const String _tag = "CloudReplayStream";
  final RapidNativeCloudReplayStream _nativeStream;
  CloudReplayChunkNotFoundListener? _notFoundListener;
  CloudReplayCompleteListener? _completeListener;
  CloudReplayRetrieveErrorListener? _retrieveErrorListener;

  CloudReplayStream._(this._nativeStream) {
    _nativeStream.setDownloadCompleteListener(() => _completeListener?.call());
    _nativeStream.setFileNotFoundListener(
        (timestampInSecond) => _notFoundListener?.call(timestampInSecond));
    _nativeStream.setRetrieveErrorListener(
        (errorCode) => _retrieveErrorListener?.call(errorCode));
  }

  set onChunkNotFound(CloudReplayChunkNotFoundListener listener) =>
      _notFoundListener = listener;
  set onComplete(CloudReplayCompleteListener listener) =>
      _completeListener = listener;
  set onRetrieveError(CloudReplayRetrieveErrorListener listener) =>
      _retrieveErrorListener = listener;

  void prepare(
    int startTimestampInSecond,
    int endTimestampInSecond,
    String storageId, {
    List<String>? fileNameList,
    CloudReplayMode replayMode = CloudReplayMode.normal,
  }) =>
      _nativeStream.prepare(
        startTimestampInSecond,
        endTimestampInSecond,
        storageId,
        fileNameList: fileNameList,
        replayMode: replayMode.index,
      );
  void start() => _nativeStream.start();
  Future<CloudReplayDownloadStartResult> startDownload(
    int startTimestampInSecond,
    int endTimestampInSecond,
    String storageId, {
    List<String>? fileNameList,
  }) async {
    final nativeResult = await compute(
      _startCloudReplayDownload,
      _CloudReplayDownloadStartRequest(
        _nativeStream.pointerAddress,
        startTimestampInSecond,
        endTimestampInSecond,
        storageId,
        fileNameList,
      ),
    );
    final type = nativeResult.type >= 0 &&
            nativeResult.type < CloudReplayDownloadStartResultType.values.length
        ? CloudReplayDownloadStartResultType.values[nativeResult.type]
        : CloudReplayDownloadStartResultType.invalidResponse;
    return CloudReplayDownloadStartResult(
      type: type,
      errorCode: nativeResult.errorCode,
      requestedDurationSeconds: nativeResult.requestedDurationSeconds,
      permittedDurationSeconds: nativeResult.permittedDurationSeconds,
    );
  }

  void seek(int timestampInSecond) => _nativeStream.seek(timestampInSecond);
  void pause() => _nativeStream.pause();
  void resume() => _nativeStream.resume();
  void stop() => _nativeStream.stop();
  void destroy() => _nativeStream.destroy();
  Pointer<Void>? provider({int cameraIndex = 0}) =>
      _nativeStream.indexedProvider(cameraIndex);
  void setSpeed(CloudReplaySpeed speed) => _nativeStream.setSpeed(speed.index);

  void _enableDownloadControl(bool enable) =>
      _nativeStream.enableDownloadControl(enable);

  static CloudReplayStream create(String deviceId) {
    final nativeLiveStream = RapidNativeCloudReplayStream(deviceId);
    nativeLiveStream.create();
    return CloudReplayStream._(nativeLiveStream);
  }
}

class _CloudReplayDownloadStartRequest {
  final int streamAddress;
  final int startTimestampInSecond;
  final int endTimestampInSecond;
  final String storageId;
  final List<String>? fileNameList;

  const _CloudReplayDownloadStartRequest(
    this.streamAddress,
    this.startTimestampInSecond,
    this.endTimestampInSecond,
    this.storageId,
    this.fileNameList,
  );
}

RapidNativeCloudReplayDownloadStartResult _startCloudReplayDownload(
  _CloudReplayDownloadStartRequest request,
) =>
    rapidNativeCloudReplayStartDownload(
      request.streamAddress,
      request.startTimestampInSecond,
      request.endTimestampInSecond,
      request.storageId,
      request.fileNameList,
    );
