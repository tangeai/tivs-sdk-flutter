part of 'library.dart';

enum PixelFormat {
  yuv420p,
}

class PixelFrame {
  final int width;
  final int height;
  final PixelFormat format;
  final Uint8List data;

  PixelFrame._(this.width, this.height, this.format, this.data);
}

class NativeTimestampPort {
  ReceivePort? _port;
  int _generation = 0;

  SendPort reset(void Function(int) listener,
      {int Function()? currentTimestamp}) {
    close();
    final generation = _generation;
    final port = ReceivePort();
    _port = port;
    port.listen((dynamic message) {
      if (generation != _generation || message is! int) return;
      if (currentTimestamp != null && message != currentTimestamp()) return;
      listener(message);
    });
    return port.sendPort;
  }

  void close() {
    _generation++;
    _port?.close();
    _port = null;
  }
}

class RapidNativePlayer {
  static const String _tag = "NativePlayer";
  static const int _nativeRenderStateStarted = 0;
  Pointer<Void>? _ptr;
  int _outputToken = 0;

  bool _recording = false;

  Function(int)? _renderStatusListener;
  Function(int)? _recordDurationListener;
  Function(int)? _ptsListener;
  Function(int)? _utsListener;

  Function(int, int)? _pixelSizeListener;

  late final ReceivePort _receivePort;
  late final SendPort _sendPort;
  late final ReceivePort _recordDurationReceivePort;
  late final SendPort _recordDurationSendPort;
  late final ReceivePort _ptsReceivePort;
  late final SendPort _ptsSendPort;
  final NativeTimestampPort _utsNotifications = NativeTimestampPort();
  late SendPort _utsSendPort;
  int _lastRecordDurationLogSecond = -1;

  int _pixelWidth = 0;
  int _pixelHeight = 0;

  bool create() {
    _receivePort = ReceivePort();
    _sendPort = _receivePort.sendPort;
    _recordDurationReceivePort = ReceivePort();
    _recordDurationSendPort = _recordDurationReceivePort.sendPort;
    _ptsReceivePort = ReceivePort();
    _ptsSendPort = _ptsReceivePort.sendPort;
    _utsSendPort = _utsNotifications.reset((value) => _utsListener?.call(value));

    _ptr = mediaApiPlayerBinding.RAPID_MediaPlayer_Create();
    if (Platform.isAndroid) {
      _outputToken = mediaApiPlayerBinding.RAPID_MediaPlayer_GetOutputToken(_ptr!);
    }

    mediaApiPlayerBinding.RAPID_MediaPlayer_SetRenderStatusSendPort(
        _ptr!, _sendPort.nativePort);
    if (mediaApiPlayerBinding.supportsRecordDurationSendPort) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetRecordDurationSendPort(
          _ptr!, _recordDurationSendPort.nativePort);
    } else {
      Logging.i(_tag, "record duration send port is not supported");
    }
    _receivePort.asBroadcastStream().listen((dynamic message) {
      if (message is int) {
        _onRenderStatusChanged(message);

        if (message == _nativeRenderStateStarted) {
          final width =
              mediaApiPlayerBinding.RAPID_MediaPlayer_GetPixelWidth(_ptr!);
          final height =
              mediaApiPlayerBinding.RAPID_MediaPlayer_GetPixelHeight(_ptr!);
          if (_pixelWidth != width || _pixelHeight != height) {
            _pixelWidth = width;
            _pixelHeight = height;
            _onPixelSizeChanged(_pixelWidth, _pixelHeight);
          }
        }
      }
    });
    _recordDurationReceivePort.asBroadcastStream().listen((dynamic message) {
      if (message is int) {
        _onRecordDurationChanged(message);
      }
    });
    _ptsReceivePort.asBroadcastStream().listen((dynamic message) {
      if (message is int) _ptsListener?.call(message);
    });
    return _ptr != nullptr;
  }

  void _onRenderStatusChanged(int state) {
    _renderStatusListener?.call(state);
  }

  void _onPixelSizeChanged(int width, int height) {
    _pixelSizeListener?.call(width, height);
  }

  void _onRecordDurationChanged(int durationMs) {
    final durationSecond = durationMs ~/ Duration.millisecondsPerSecond;
    if (durationMs == 0 || durationSecond != _lastRecordDurationLogSecond) {
      _lastRecordDurationLogSecond = durationSecond;
      Logging.i(_tag,
          "[recordDurationCallback] received, durationMs=$durationMs, hasListener=${_recordDurationListener != null}");
    }
    _recordDurationListener?.call(durationMs);
  }

  set onRenderState(Function(int) listener) {
    _renderStatusListener = listener;
  }

  set onPixelSizeChanged(Function(int, int) listener) {
    _pixelSizeListener = listener;
  }

  set onRecordDurationChanged(Function(int) listener) {
    _recordDurationListener = listener;
    Logging.i(_tag,
        "[setRecordDurationListener] registered, playerPtr=$_ptr, recording=$_recording, durationMs=${recordDurationMs()}");
  }

  set onPresentationTimestamp(Function(int) listener) {
    _ptsListener = listener;
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetPtsSendPort(
          _ptr!, _ptsSendPort.nativePort);
    }
  }

  set onUniversalTimestamp(Function(int) listener) {
    _utsListener = listener;
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetUtsSendPort(
          _ptr!, _utsSendPort.nativePort);
    }
  }

  void resetUniversalTimestampNotifications() {
    if (_ptr == null || _ptr == nullptr) return;
    _utsSendPort = _utsNotifications.reset(
      (value) => _utsListener?.call(value),
      currentTimestamp: uts,
    );
    mediaApiPlayerBinding.RAPID_MediaPlayer_SetUtsSendPort(
        _ptr!, _utsSendPort.nativePort);
  }

  void setVout(Pointer<Void> vout) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetVout(_ptr!, vout);
    } else {
      Logging.i(_tag, "setVout no valid player to set vout");
    }
  }

  void enableBuffering(bool enable) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_EnableBuffering(
          _ptr!, enable ? 1 : 0);
    } else {
      Logging.i(_tag, "enableBuffering no valid player to enable buffering");
    }
  }

  void setBufferingMode(int mode, int fixedWaterMarkMs) {
    if (_ptr != null && _ptr != nullptr) {
      if (mediaApiPlayerBinding.supportsSetBufferingMode) {
        mediaApiPlayerBinding.RAPID_MediaPlayer_SetBufferingMode(
            _ptr!, mode, fixedWaterMarkMs);
      } else {
        Logging.i(_tag, "set buffering mode is not supported");
      }
    } else {
      Logging.i(_tag, "setBufferingMode no valid player to set buffering mode");
    }
  }

  void setAutoBufferingMax(int value) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetAutoMaxWaterMark(_ptr!, value);
    } else {
      Logging.i(
          _tag, "setAutoBufferingMax no valid player to set buffering max");
    }
  }

  bool setLocalReplayAudioContinuity(bool enabled) {
    if (_ptr == null || _ptr == nullptr ||
        !mediaApiPlayerBinding.supportsSetLocalReplayAudioContinuity) {
      Logging.i(_tag, "setLocalReplayAudioContinuity is unavailable");
      return false;
    }
    mediaApiPlayerBinding.RAPID_MediaPlayer_SetLocalReplayAudioContinuity(
        _ptr!, enabled ? 1 : 0);
    return true;
  }

  void setClockMode(int mode) {
    if (_ptr != null && _ptr != nullptr) {
      if (mediaApiPlayerBinding.supportsSetClockMode) {
        mediaApiPlayerBinding.RAPID_MediaPlayer_SetClockMode(_ptr!, mode);
      } else {
        Logging.i(_tag, "set clock mode is not supported");
      }
    } else {
      Logging.i(_tag, "setClockMode no valid player to set clock mode");
    }
  }

  void setVideoDecoderPreference(int preference) {
    if (_ptr != null && _ptr != nullptr) {
      if (mediaApiPlayerBinding.supportsSetVideoDecoderPreference) {
        mediaApiPlayerBinding.RAPID_MediaPlayer_SetVideoDecoderPreference(
            _ptr!, preference);
      } else {
        Logging.i(_tag, "set video decoder preference is not supported");
      }
    } else {
      Logging.i(_tag,
          "setVideoDecoderPreference no valid player to set decoder preference");
    }
  }

  void configureAudioProcessing(int nsLevel, int agcLevel) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_ConfigureAudioProcessing(
          _ptr!, nsLevel, agcLevel);
    }
  }

  void prepare(Pointer<Void> providerPtr) {
    if (_ptr != null && _ptr != nullptr) {
      Pointer<Void> ffiPointer = providerPtr.cast<Void>();
      Logging.i(_tag, "prepare playerPtr = $_ptr, providerPtr = $providerPtr");
      mediaApiPlayerBinding.RAPID_MediaPlayer_Prepare(_ptr!, ffiPointer);
    } else {
      Logging.i(_tag, "prepare no valid player to prepare");
    }
  }

  bool recording() {
    return _recording;
  }

  bool startRecord(String path) {
    if (_ptr != null && _ptr != nullptr) {
      Pointer<Utf8> pathC = path.toNativeUtf8();
      int ret =
          mediaApiPlayerBinding.RAPID_MediaPlayer_StartRecord(_ptr!, pathC);
      calloc.free(pathC);
      _recording = ret == 1;
      _lastRecordDurationLogSecond = -1;
      Logging.i(
          _tag, "[startRecord] result=$ret, recording=$_recording, path=$path");
      return _recording;
    }

    Logging.i(_tag, "[startRecord] failed, playerPtrValid=false, path=$path");
    return false;
  }

  bool stopRecord() {
    if (_ptr != null && _ptr != nullptr) {
      _recording = false;
      final ret = mediaApiPlayerBinding.RAPID_MediaPlayer_StopRecord(_ptr!);
      Logging.i(_tag, "[stopRecord] result=$ret");
      return ret == 1;
    }
    Logging.i(_tag, "[stopRecord] failed, playerPtrValid=false");
    return false;
  }

  int recordDurationMs() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_GetRecordDurationMs(_ptr!);
    }
    return 0;
  }

  bool startDump() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_StartDump(_ptr!) == 0;
    }
    return false;
  }

  bool stopDump() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_StopDump(_ptr!) == 0;
    }
    return false;
  }

  @internal
  void enableVideoFrameDump(bool enable) {
    if (!kDebugMode) {
      throw UnsupportedError('Video frame diagnostics require a Debug build');
    }
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_EnableVideoFrameDump(
          _ptr!, enable ? 1 : 0);
    }
  }

  bool capture(String path) {
    if (_ptr != null && _ptr != nullptr) {
      Pointer<Utf8> pathC = path.toNativeUtf8();
      int ret = mediaApiPlayerBinding.RAPID_MediaPlayer_Capture(_ptr!, pathC);
      calloc.free(pathC);
      return ret == 1;
    } else {
      return false;
    }
  }

  void start() {
    if (_ptr != null && _ptr != nullptr) {
      Logging.i(_tag, "start player start ...");
      mediaApiPlayerBinding.RAPID_MediaPlayer_Start(_ptr!);
    } else {
      Logging.i(_tag, "start no valid player to start");
    }
  }

  void enableAudio(bool enable) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_EnableAout(_ptr!, enable ? 1 : 0);
    } else {
      Logging.i(_tag, "enableAudio no valid player to enable audio");
    }
  }

  void enableVideo(bool enable) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_EnableVout(_ptr!, enable ? 1 : 0);
    } else {
      Logging.i(_tag, "enableVideo no valid player to enable video");
    }
  }

  void stop() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_Stop(_ptr!);
    } else {
      Logging.i(_tag, "stop no valid player to stop");
    }
  }

  void mute(bool mute) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_Mute(_ptr!, mute ? 1 : 0);
    } else {
      Logging.i(_tag, "mute no valid player to mute");
    }
  }

  bool isMute() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_IsMute(_ptr!) == 1;
    } else {
      Logging.i(_tag, "isMute no valid player to check mute");
      return false;
    }
  }

  int pixelWidth() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_GetPixelWidth(_ptr!);
    } else {
      return 0;
    }
  }

  int pixelHeight() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_GetPixelHeight(_ptr!);
    } else {
      return 0;
    }
  }

  int uts() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_GetUts(_ptr!);
    } else {
      return 0;
    }
  }

  int pts() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_GetPts(_ptr!);
    } else {
      return 0;
    }
  }

  int muxerQueueSize() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiPlayerBinding.RAPID_MediaPlayer_GetMuxerQueueSize(_ptr!);
    } else {
      return 0;
    }
  }

  void resume() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_Resume(_ptr!);
    } else {
      Logging.i(_tag, "resume no valid player to resume");
    }
  }

  void pause() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_Pause(_ptr!);
    } else {
      Logging.i(_tag, "pause no valid player to pause");
    }
  }

  void destroy() {
    if (_ptr != null && _ptr != nullptr) {
      Logging.i(_tag, "destroy player destroy ...");
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetPtsSendPort(_ptr!, 0);
      mediaApiPlayerBinding.RAPID_MediaPlayer_SetUtsSendPort(_ptr!, 0);
      mediaApiPlayerBinding.RAPID_MediaPlayer_Destroy(_ptr!);
      _ptr = null;
      _receivePort.close();
      _recordDurationReceivePort.close();
      _ptsReceivePort.close();
      _utsNotifications.close();
    } else {
      Logging.i(_tag, "destroy no valid player to destroy");
    }
  }

  void bindingPrimaryPlayer(RapidNativePlayer primaryPlayer) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiPlayerBinding.RAPID_MediaPlayer_BindPlayer(
          _ptr!, primaryPlayer._ptr!);
    } else {
      Logging.i(_tag, "bindingPrimaryPlayer no valid player to bind");
    }
  }

  int get ptr => _ptr != null ? _ptr!.address : 0;
  int get outputToken => _outputToken;

  String? get metricsSnapshot {
    if (_ptr == null || _ptr == nullptr) {
      return null;
    }

    final jsonPtr =
        mediaApiPlayerBinding.RAPID_MediaPlayer_GetRuntimeMetricsJson(_ptr!);
    if (jsonPtr == nullptr || jsonPtr.address == 0) {
      return null;
    }

    final jsonStr = jsonPtr.toDartString();
    mediaApiPlayerBinding.RAPID_MediaPlayer_FreeJson(jsonPtr);
    return jsonStr;
  }

  String? get startupMetricsSnapshot {
    if (_ptr == null || _ptr == nullptr) {
      return null;
    }

    final jsonPtr =
        mediaApiPlayerBinding.RAPID_MediaPlayer_GetStartupMetricsJson(_ptr!);
    if (jsonPtr == nullptr || jsonPtr.address == 0) {
      return null;
    }

    final jsonStr = jsonPtr.toDartString();
    mediaApiPlayerBinding.RAPID_MediaPlayer_FreeJson(jsonPtr);
    return jsonStr;
  }

  PixelFrame? currentPixelFrame() {
    if (_ptr == null || _ptr == nullptr) return null;
    final framePtr =
        mediaApiPlayerBinding.RAPID_MediaPlayer_GetPixelFrame(_ptr!);
    if (framePtr == nullptr) return null;

    try {
      final frame = framePtr.ref;
      final width = frame.width;
      final height = frame.height;
      final dataSize = frame.data_size;

      if (dataSize <= 0 || frame.data == nullptr) return null;

      final cData = frame.data.cast<Uint8>().asTypedList(dataSize);
      final dartData = Uint8List.fromList(cData);

      return PixelFrame._(width, height, PixelFormat.yuv420p, dartData);
    } finally {
      mediaApiPlayerBinding.RAPID_Media_PixelFrame_Free(framePtr);
    }
  }
}
