part of 'library.dart';

class RapidNativeStreamDiagnostics {
  static void enableDebugging(bool enable) =>
      coreApiStreamBinding.RAPID_Core_Stream_EnableDebugging(enable ? 1 : 0);
}

/// Live Stream

class RapidNativeLiveStream {
  static const String _tag = "NativeStream";
  final RapidNativePipe _nativePipe;

  RapidNativeLiveStream(RapidNativePipe pipe) : _nativePipe = pipe {
    _receivePortOfExternalData = ReceivePort();
    _sendPortOfExternalData = _receivePortOfExternalData.sendPort;
    _receivePortOfExternalData.asBroadcastStream().listen((dynamic message) {
      if (message is! List<dynamic> || message.length != 4) return;
      final type = message[0] as int? ?? 0;
      final data1 = message[1] as int? ?? 0;
      final data2 = message[2] as int? ?? 0;
      final buffer = message[3] as Uint8List?;
      _externalDataListener?.call(type, data1, data2, buffer);
    });
  }

  Pointer<Void>? _streamPtr;
  RapidExternalDataListener? _externalDataListener;
  late final ReceivePort _receivePortOfExternalData;
  late final SendPort _sendPortOfExternalData;

  bool createPrimary({bool enableAudio = true}) {
    if (_nativePipe._pipePtr == null || _nativePipe._pipePtr == nullptr) {
      Logging.i(_tag, "createPrimary no valid pipe to create stream");
      return false;
    }

    Logging.i(_tag, "createPrimary enableAudio = $enableAudio");
    _streamPtr =
        coreApiStreamBinding.RAPID_Core_LiveStream_CreateDefaultWithAudio(
      _nativePipe._pipePtr!,
      enableAudio ? 1 : 0,
    );
    if (_streamPtr == nullptr) {
      Logging.i(_tag, "createPrimary failed to create stream");
      return false;
    }

    _syncExternalDataSendPort();
    return true;
  }

  bool createSecondary({bool enableAudio = false}) {
    if (_nativePipe._pipePtr == null || _nativePipe._pipePtr == nullptr) {
      Logging.i(_tag, "createSecondary no valid pipe to create stream");
      return false;
    }

    Logging.i(_tag, "createSecondary enableAudio = $enableAudio");
    _streamPtr = enableAudio
        ? coreApiStreamBinding.RAPID_Core_LiveStream_CreateSecondaryWithAudio(
            _nativePipe._pipePtr!,
          )
        : coreApiStreamBinding.RAPID_Core_LiveStream_CreateSecondary(
            _nativePipe._pipePtr!,
          );
    if (_streamPtr == nullptr) {
      Logging.i(_tag, "createSecondary failed to create stream");
      return false;
    }

    _syncExternalDataSendPort();
    return true;
  }

  void start() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      Logging.i(_tag, "start stream start ...");
      coreApiStreamBinding.RAPID_Core_LiveStream_Start(_streamPtr!);
    } else {
      Logging.i(_tag, "start no valid stream to start");
    }
  }

  void stop() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LiveStream_Stop(_streamPtr!);
    } else {
      Logging.i(_tag, "stop no valid stream to stop");
    }
  }

  void destroy() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiExternalBinding.RAPID_Core_LiveStream_SetUserExternalDataSendPort(
        _streamPtr!,
        0,
      );
      coreApiStreamBinding.RAPID_Core_LiveStream_Release(_streamPtr!);
      _streamPtr = null;
    } else {
      Logging.i(_tag, "destroy no valid stream to destroy");
    }
    _receivePortOfExternalData.close();
  }

  void setExternalDataListener(RapidExternalDataListener? listener) {
    _externalDataListener = listener;
    _syncExternalDataSendPort();
  }

  void switchQuality(int quality) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LiveStream_SwitchQuality(
        _streamPtr!,
        quality,
      );
    } else {
      Logging.i(_tag, "switchQuality no valid stream to switch quality");
    }
  }

  void highQuality() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LiveStream_SwitchHighQuality(_streamPtr!);
    } else {
      Logging.i(_tag, "highQuality no valid stream to switch quality");
    }
  }

  void lowQuality() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LiveStream_SwitchLowQuality(_streamPtr!);
    } else {
      Logging.i(_tag, "lowQuality no valid stream to switch quality");
    }
  }

  int currentQuality() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_LiveStream_CurrentQuality(
        _streamPtr!,
      );
    } else {
      Logging.i(_tag, "currentQuality no valid stream to get current quality");
      return -1;
    }
  }

  void requireKeyFrame() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LiveStream_RequestKeyFrame(_streamPtr!);
    }
  }

  bool isStarted() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_LiveStream_IsStarted(
            _streamPtr!,
          ) ==
          1;
    } else {
      Logging.i(_tag, "isStarted no valid stream to check start status");
      return false;
    }
  }

  Pointer<Void>? indexedProvider(int index) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_LiveStream_IndexedProvider(
        _streamPtr!,
        index,
      );
    } else {
      Logging.i(
        _tag,
        "indexedProvider no valid stream to get indexed provider",
      );
      return nullptr;
    }
  }

  // ignore: non_constant_identifier_names
  String? receive_metrics({int cameraIndex = 0}) {
    if (_streamPtr == null || _streamPtr == nullptr) {
      return null;
    }

    Pointer<Utf8> jsonPtr;
    try {
      jsonPtr = coreApiStreamBinding.RAPID_Core_LiveStream_GetReceiveMetrics(
        _streamPtr!,
        cameraIndex,
      );
    } on ArgumentError {
      return null;
    }
    if (jsonPtr == nullptr || jsonPtr.address == 0) {
      return null;
    }

    try {
      return jsonPtr.toDartString();
    } finally {
      coreApiStreamBinding.RAPID_Core_LiveStream_FreeMetrics(jsonPtr);
    }
  }

  String? metricsSnapshot({int cameraIndex = 0}) {
    if (_streamPtr == null || _streamPtr == nullptr) {
      return null;
    }

    final jsonPtr = coreApiStreamBinding.RAPID_Core_LiveStream_GetMetrics(
      _streamPtr!,
      cameraIndex,
    );
    if (jsonPtr == nullptr || jsonPtr.address == 0) {
      return null;
    }

    try {
      return jsonPtr.toDartString();
    } finally {
      coreApiStreamBinding.RAPID_Core_LiveStream_FreeMetrics(jsonPtr);
    }
  }

  String? firstPacketMetricsSnapshot({int cameraIndex = 0}) {
    if (_streamPtr == null || _streamPtr == nullptr) {
      return null;
    }

    final jsonPtr =
        coreApiStreamBinding.RAPID_Core_LiveStream_GetFirstPacketMetricsJson(
      _streamPtr!,
      cameraIndex,
    );
    if (jsonPtr == nullptr || jsonPtr.address == 0) {
      return null;
    }

    try {
      return jsonPtr.toDartString();
    } finally {
      coreApiStreamBinding.RAPID_Core_LiveStream_FreeMetrics(jsonPtr);
    }
  }

  void _syncExternalDataSendPort() {
    if (_streamPtr == null || _streamPtr == nullptr) {
      return;
    }
    final port =
        _externalDataListener == null ? 0 : _sendPortOfExternalData.nativePort;
    coreApiExternalBinding.RAPID_Core_LiveStream_SetUserExternalDataSendPort(
      _streamPtr!,
      port,
    );
  }
}

/// Cloud Replay Stream

typedef CloudReplayFileNotFoundListener = void Function(int timestampInSecond);
typedef CloudReplayFileDownloadCompleteListener = void Function();
typedef CloudReplayRetrieveErrorListener = void Function(int errorCode);

class RapidNativeCloudReplayDownloadStartResult {
  final int type;
  final int errorCode;
  final int requestedDurationSeconds;
  final int permittedDurationSeconds;

  const RapidNativeCloudReplayDownloadStartResult(
    this.type,
    this.errorCode,
    this.requestedDurationSeconds,
    this.permittedDurationSeconds,
  );
}

class RapidNativeCloudReplayStream {
  static const String _tag = "NativeCloudReplayStream";

  final String _deviceId;

  RapidNativeCloudReplayStream(String deviceId) : _deviceId = deviceId;
  Pointer<Void>? _streamPtr;
  int get pointerAddress => _streamPtr?.address ?? 0;

  CloudReplayFileNotFoundListener? _fileNotFoundListener;
  CloudReplayFileDownloadCompleteListener? _downloadCompleteListener;
  CloudReplayRetrieveErrorListener? _retrieveErrorListener;

  late final ReceivePort _receivePortOfFileNotFound;
  late final SendPort _sendPortOfFileNotFound;

  late final ReceivePort _receivePortOfDownloadComplete;
  late final SendPort _sendPortOfDownloadComplete;

  late final ReceivePort _receivePortOfRetrieveError;
  late final SendPort _sendPortOfRetrieveError;

  void setFileNotFoundListener(CloudReplayFileNotFoundListener listener) {
    _fileNotFoundListener = listener;
  }

  void setDownloadCompleteListener(
    CloudReplayFileDownloadCompleteListener listener,
  ) {
    _downloadCompleteListener = listener;
  }

  void setRetrieveErrorListener(CloudReplayRetrieveErrorListener listener) {
    _retrieveErrorListener = listener;
  }

  bool create() {
    _receivePortOfFileNotFound = ReceivePort();
    _sendPortOfFileNotFound = _receivePortOfFileNotFound.sendPort;

    _receivePortOfDownloadComplete = ReceivePort();
    _sendPortOfDownloadComplete = _receivePortOfDownloadComplete.sendPort;

    _receivePortOfRetrieveError = ReceivePort();
    _sendPortOfRetrieveError = _receivePortOfRetrieveError.sendPort;

    Pointer<Utf8> deviceIdC = _deviceId.toNativeUtf8();
    _streamPtr = coreApiStreamBinding.RAPID_Core_CloudReplayStream_Create(
      deviceIdC,
    );

    coreApiStreamBinding.RAPID_Core_CloudReplayStream_SetFileNotFoundSendPort(
      _streamPtr!,
      _sendPortOfFileNotFound.nativePort,
    );
    _receivePortOfFileNotFound.asBroadcastStream().listen((dynamic message) {
      if (message is int) {
        _fileNotFoundListener?.call(message);
      }
    });

    coreApiStreamBinding
        .RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPort(
      _streamPtr!,
      _sendPortOfDownloadComplete.nativePort,
    );
    _receivePortOfDownloadComplete.asBroadcastStream().listen((
      dynamic message,
    ) {
      if (message is int) {
        if (message == 1) {
          _downloadCompleteListener?.call();
        }
      }
    });

    coreApiStreamBinding.RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPort(
      _streamPtr!,
      _sendPortOfRetrieveError.nativePort,
    );
    _receivePortOfRetrieveError.asBroadcastStream().listen((dynamic message) {
      if (message is int) {
        _retrieveErrorListener?.call(message);
      }
    });

    calloc.free(deviceIdC);
    return _streamPtr != nullptr;
  }

  void pause() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_Pause(_streamPtr!);
    }
  }

  void resume() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_Resume(_streamPtr!);
    }
  }

  void prepare(
    int startTimestampInSecond,
    int endTimestampInSecond,
    String storageId, {
    List<String>? fileNameList,
    int replayMode = 0,
  }) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      Pointer<Utf8> storageIdC = storageId.toNativeUtf8();
      final fileNameListJson = (fileNameList == null || fileNameList.isEmpty)
          ? ""
          : jsonEncode(fileNameList);
      Pointer<Utf8> fileNameListJsonC = fileNameListJson.toNativeUtf8();
      if (replayMode == 0) {
        coreApiStreamBinding.RAPID_Core_CloudReplayStream_Prepare(
          _streamPtr!,
          startTimestampInSecond,
          endTimestampInSecond,
          storageIdC,
          fileNameListJsonC,
        );
      } else {
        coreApiStreamBinding.RAPID_Core_CloudReplayStream_PrepareV2(
          _streamPtr!,
          startTimestampInSecond,
          endTimestampInSecond,
          storageIdC,
          fileNameListJsonC,
          replayMode,
        );
      }
      calloc.free(storageIdC);
      calloc.free(fileNameListJsonC);
    }
  }

  void start() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_Start(_streamPtr!);
    }
  }

  RapidNativeCloudReplayDownloadStartResult startDownload(
    int startTimestampInSecond,
    int endTimestampInSecond,
    String storageId, {
    List<String>? fileNameList,
  }) {
    return rapidNativeCloudReplayStartDownload(
      pointerAddress,
      startTimestampInSecond,
      endTimestampInSecond,
      storageId,
      fileNameList,
    );
  }

  void seek(int timestampInSecond) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_Seek(
        _streamPtr!,
        timestampInSecond,
      );
    }
  }

  void stop() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_Stop(_streamPtr!);
    }
  }

  void setSpeed(int speed) {
    // check speed must be greater than 0 and smaller than 4
    if (speed < 0 || speed > 3) {
      throw Exception("speed must be: 0~3");
    }

    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_SetSpeed(
        _streamPtr!,
        speed,
      );
    } else {
      Logging.i(_tag, "setSpeed no valid stream to set speed");
    }
  }

  bool isStarted() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_CloudReplayStream_IsStarted(
            _streamPtr!,
          ) ==
          1;
    } else {
      return false;
    }
  }

  Pointer<Void>? indexedProvider(int index) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_CloudReplayStream_IndexedProvider(
        _streamPtr!,
        index,
      );
    } else {
      return nullptr;
    }
  }

  void enableDownloadControl(bool enable) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_EnableDownloadControl(
        _streamPtr!,
        enable ? 1 : 0,
      );
    } else {
      Logging.i(
        _tag,
        "enableDownloadControl no valid stream to enable download control",
      );
    }
  }

  void destroy() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_Release(_streamPtr!);
      _streamPtr = null;
    }
  }
}

RapidNativeCloudReplayDownloadStartResult rapidNativeCloudReplayStartDownload(
  int streamAddress,
  int startTimestampInSecond,
  int endTimestampInSecond,
  String storageId,
  List<String>? fileNameList,
) {
  if (streamAddress == 0) {
    return const RapidNativeCloudReplayDownloadStartResult(3, -3, 0, 30);
  }

  final streamPtr = Pointer<Void>.fromAddress(streamAddress);
  final storageIdC = storageId.toNativeUtf8();
  final fileNameListJson = (fileNameList == null || fileNameList.isEmpty)
      ? ""
      : jsonEncode(fileNameList);
  final fileNameListJsonC = fileNameListJson.toNativeUtf8();
  final result =
      coreApiStreamBinding.RAPID_Core_CloudReplayStream_StartDownload(
    streamPtr,
    startTimestampInSecond,
    endTimestampInSecond,
    storageIdC,
    fileNameListJsonC,
  );
  calloc.free(storageIdC);
  calloc.free(fileNameListJsonC);
  return RapidNativeCloudReplayDownloadStartResult(
    result.type,
    result.error_code,
    result.requested_duration_seconds,
    result.permitted_duration_seconds,
  );
}

/// Local Replay Stream

typedef LocalReplaySeekErrorListener = void Function(
  int errorCode,
  int targetTimestampSecond,
  int actualTimestampSecond,
);

class RapidNativeLocalReplayStream {
  static const String _tag = "NativeLocalReplayStream";

  final RapidNativePipe _nativePipe;

  RapidNativeLocalReplayStream(RapidNativePipe pipe) : _nativePipe = pipe {
    _receivePortOfSeekError = ReceivePort();
    _sendPortOfSeekError = _receivePortOfSeekError.sendPort;
    _receivePortOfSeekError.listen((dynamic message) {
      if (message is! List<dynamic> || message.length != 4) return;
      final errorCode = message[0] as int? ?? 0;
      final targetTimestampSecond = message[1] as int? ?? 0;
      final actualTimestampSecond = message[2] as int? ?? 0;
      _seekErrorListener?.call(
        errorCode,
        targetTimestampSecond,
        actualTimestampSecond,
      );
    });
  }
  Pointer<Void>? _streamPtr;
  LocalReplaySeekErrorListener? _seekErrorListener;
  late final ReceivePort _receivePortOfSeekError;
  late final SendPort _sendPortOfSeekError;
  bool _seekErrorPortEnabled = false;

  void setSeekErrorListener(LocalReplaySeekErrorListener? listener) {
    _seekErrorListener = listener;
  }

  bool setAudioUtcFallback(bool enabled) {
    if (_streamPtr == null || _streamPtr == nullptr || isStarted()) {
      Logging.i(_tag, "setAudioUtcFallback requires a stopped stream");
      return false;
    }
    if (!libRapidCore
        .providesSymbol('RAPID_Core_LocalReplayStream_SetAudioUtcFallback')) {
      Logging.i(_tag, "setAudioUtcFallback is unavailable in this native SDK");
      return false;
    }
    coreApiStreamBinding.RAPID_Core_LocalReplayStream_SetAudioUtcFallback(
      _streamPtr!,
      enabled ? 1 : 0,
    );
    return true;
  }

  bool create({bool enableAudio = true}) {
    if (_nativePipe._pipePtr != null && _nativePipe._pipePtr != nullptr) {
      _streamPtr =
          coreApiStreamBinding.RAPID_Core_LocalReplayStream_CreateWithAudio(
        _nativePipe._pipePtr!,
        enableAudio ? 1 : 0,
      );
      if (_streamPtr != nullptr) {
        if (libRapidCore.providesSymbol(
            'RAPID_Core_LocalReplayStream_SetSeekErrorSendPort')) {
          coreApiStreamBinding
              .RAPID_Core_LocalReplayStream_SetSeekErrorSendPort(
            _streamPtr!,
            _sendPortOfSeekError.nativePort,
          );
          _seekErrorPortEnabled = true;
        }
        return true;
      } else {
        Logging.i(_tag, "create failed to create stream");
        return false;
      }
    } else {
      Logging.i(_tag, "no valid pipe to create stream");
      return false;
    }
  }

  void prepare(int startTimestampInSecond, int endTimestampInSecond) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_Prepare(
        _streamPtr!,
        startTimestampInSecond,
        endTimestampInSecond,
      );
    } else {
      Logging.i(_tag, "prepare no valid stream to prepare");
    }
  }

  void start() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      Logging.i(_tag, "start stream start ...");
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_Start(_streamPtr!);
    } else {
      Logging.i(_tag, "start no valid stream to start");
    }
  }

  void seek(
    int timestampInSecond, {
    int startMode = 0,
  }) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      Logging.i(
        _tag,
        "seek timestampInSecond = $timestampInSecond startMode = $startMode",
      );
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_SeekWithModeAndTimezone(
        _streamPtr!,
        timestampInSecond,
        startMode,
        RAPID_Core_LocalReplayTimezone_Unspecified,
      );
    } else {
      Logging.i(_tag, "seek no valid stream to seek");
    }
  }

  void updateLastRenderedUtc(int timestampMs) {
    if (_streamPtr != null && _streamPtr != nullptr && timestampMs > 0) {
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_UpdateLastRenderedUtc(
        _streamPtr!,
        timestampMs,
      );
    }
  }

  void stop() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_Stop(_streamPtr!);
    } else {
      Logging.i(_tag, "stop no valid stream to stop");
    }
  }

  void pause() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_Pause(_streamPtr!);
    } else {
      Logging.i(_tag, "pause no valid stream to pause");
    }
  }

  void resume() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_Resume(_streamPtr!);
    } else {
      Logging.i(_tag, "resume no valid stream to resume");
    }
  }

  bool isPaused() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_LocalReplayStream_IsPaused(
            _streamPtr!,
          ) ==
          1;
    } else {
      Logging.i(_tag, "isPaused no valid stream to check pause status");
      return false;
    }
  }

  void setSpeed(int speed) {
    // check speed must be greater than 0 and smaller than 4
    if (speed < 0 || speed > 3) {
      throw Exception("speed must be: 0~3");
    }

    if (_streamPtr != null && _streamPtr != nullptr) {
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_SetSpeed(
        _streamPtr!,
        speed,
      );
    } else {
      Logging.i(_tag, "setSpeed no valid stream to set speed");
    }
  }

  void destroy() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      if (_seekErrorPortEnabled) {
        coreApiStreamBinding.RAPID_Core_LocalReplayStream_SetSeekErrorSendPort(
          _streamPtr!,
          0,
        );
      }
      coreApiStreamBinding.RAPID_Core_LocalReplayStream_Release(_streamPtr!);
      _streamPtr = null;
    } else {
      Logging.i(_tag, "destroy no valid stream to destroy");
    }
    _seekErrorListener = null;
    _receivePortOfSeekError.close();
  }

  bool isStarted() {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_LocalReplayStream_IsStarted(
            _streamPtr!,
          ) ==
          1;
    } else {
      Logging.i(_tag, "isStarted no valid stream to check start status");
      return false;
    }
  }

  Pointer<Void>? indexedProvider(int index) {
    if (_streamPtr != null && _streamPtr != nullptr) {
      return coreApiStreamBinding.RAPID_Core_LocalReplayStream_IndexedProvider(
        _streamPtr!,
        index,
      );
    } else {
      Logging.i(
        _tag,
        "indexedProvider no valid stream to get indexed provider",
      );
      return nullptr;
    }
  }
}
