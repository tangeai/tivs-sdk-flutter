part of 'library.dart';

class MediaChat {
  static const _tag = 'MediaChat';
  static const sampleRate8k = 0;
  static const sampleRate16k = 1;
  static const _legacyFullDuplexCompatConfig = IntercomAudioProcessingConfig(
    aecLevel: 1,
  );

  final RapidNativeMediaChat _nativeMediaChat;
  final RapidNativeChatChannel _nativeChatChannel;
  final Player? _playbackPlayer;
  final int _mediaChatPtr;
  bool _prepared = false;
  bool _audioProcessingConfigured = false;
  bool _androidHardwareAecEnabled = false;
  bool _androidHardwareNsEnabled = false;
  bool _androidHardwareAgcEnabled = false;
  bool _androidPlayerVoiceCommunicationEnabled = false;
  bool _iosVoiceProcessingEnabled = false;
  bool _iosVoiceProcessingActive = false;
  bool _iosVoiceProcessingAttached = false;
  bool _iosAudioIoAttached = false;
  bool _destroyed = false;
  int _sampleRate = sampleRate8k;
  Future<void> _androidAudioRecordRebuild = Future.value();
  Future<void> _iosAudioProcessingUpdate = Future.value();

  MediaChat._(
    this._nativeMediaChat,
    this._nativeChatChannel,
    this._playbackPlayer,
  ) : _mediaChatPtr = _nativeMediaChat.ptr;

  Future<bool> prepare({
    @Deprecated(
      'Deprecated: fullDuplex now maps to legacy AEC compatibility only. Use configureAudioProcessing(IntercomAudioProcessingConfig(...)) instead.',
    )
    bool fullDuplex = false,
  }) async {
    if (_prepared) return true;
    _prepared = true;
    _nativeMediaChat.setChannel(_nativeChatChannel);

    if (fullDuplex && !_audioProcessingConfigured) {
      Logging.w(
        _tag,
        '[prepare] fullDuplex is deprecated, apply legacy compat config: ns=0 aec=1 agc=0',
      );
      configureAudioProcessing(_legacyFullDuplexCompatConfig);
    } else if (fullDuplex) {
      Logging.w(
        _tag,
        '[prepare] fullDuplex is deprecated, keep explicit audio processing config',
      );
    }

    if (Platform.isIOS) {
      await _iosAudioProcessingUpdate;
      return _attachIosAudioIO(_iosVoiceProcessingEnabled);
    }

    return await _PlatformChannel.attachMediaChat(
      _mediaChatPtr,
      hardwareAec: _androidHardwareAecEnabled,
      hardwareNs: _androidHardwareNsEnabled,
      hardwareAgc: _androidHardwareAgcEnabled,
    );
  }

  void configureAudioProcessing(IntercomAudioProcessingConfig audioProcessing) {
    final androidHardwareAecEnabled =
        Platform.isAndroid && audioProcessing.aecLevel == 2;
    final iosVoiceProcessingEnabled =
        Platform.isIOS && audioProcessing.aecLevel == 2;
    final androidHardwareNsEnabled =
        androidHardwareAecEnabled && audioProcessing.nsLevel > 0;
    final androidHardwareAgcEnabled =
        androidHardwareAecEnabled && audioProcessing.agcLevel > 0;
    final androidHardwareEffectsChanged =
        _androidHardwareAecEnabled != androidHardwareAecEnabled ||
            _androidHardwareNsEnabled != androidHardwareNsEnabled ||
            _androidHardwareAgcEnabled != androidHardwareAgcEnabled;
    final shouldRebuildAndroidAudioRecord =
        Platform.isAndroid && _prepared && androidHardwareEffectsChanged;
    final wasStarted = started();
    _androidHardwareAecEnabled = androidHardwareAecEnabled;
    _androidHardwareNsEnabled = androidHardwareNsEnabled;
    _androidHardwareAgcEnabled = androidHardwareAgcEnabled;
    _iosVoiceProcessingEnabled = iosVoiceProcessingEnabled;
    final coreNsLevel = androidHardwareAecEnabled ? 0 : audioProcessing.nsLevel;
    final coreAecLevel = androidHardwareAecEnabled
        ? 0
        : iosVoiceProcessingEnabled
            ? 0
            : audioProcessing.aecLevel.clamp(0, 1);
    final coreAgcLevel =
        androidHardwareAecEnabled ? 0 : audioProcessing.agcLevel;

    Logging.i(
      _tag,
      '[configureAudioProcessing] ns=${audioProcessing.nsLevel} '
      'coreNs=$coreNsLevel '
      'aec=${audioProcessing.aecLevel} coreAec=$coreAecLevel '
      'androidHardwareAec=$_androidHardwareAecEnabled '
      'iosVoiceProcessing=$_iosVoiceProcessingEnabled '
      'androidHardwareNs=$_androidHardwareNsEnabled '
      'agc=${audioProcessing.agcLevel} coreAgc=$coreAgcLevel '
      'androidHardwareAgc=$_androidHardwareAgcEnabled '
      'rebuildAndroidAudioRecord=$shouldRebuildAndroidAudioRecord',
    );
    _audioProcessingConfigured = true;
    if (Platform.isIOS) {
      _scheduleIosAudioProcessingUpdate(
        coreNsLevel,
        coreAecLevel,
        coreAgcLevel,
        iosVoiceProcessingEnabled,
        wasStarted,
      );
    } else {
      _nativeMediaChat.configureAudioProcessing(
        coreNsLevel,
        coreAecLevel,
        coreAgcLevel,
      );
    }
    if (shouldRebuildAndroidAudioRecord) {
      _scheduleAndroidAudioRecordRebuild(
        androidHardwareAecEnabled,
        androidHardwareNsEnabled,
        androidHardwareAgcEnabled,
        wasStarted,
      );
    } else if (_androidPlayerVoiceCommunicationEnabled &&
        !androidHardwareAecEnabled) {
      unawaited(_setAndroidPlayerVoiceCommunication(false));
    }
  }

  bool started() => _nativeMediaChat.started();
  void stop() {
    _nativeMediaChat.stop();
    unawaited(_setAndroidPlayerVoiceCommunication(false));
    if (Platform.isIOS) {
      _scheduleIosVoiceProcessingRelease();
    }
  }

  bool startDump() => _nativeMediaChat.startDump();
  bool stopDump() => _nativeMediaChat.stopDump();

  Future<void> start({int sampleRate = sampleRate8k}) async {
    if (!_prepared) {
      Logging.e(_tag, '[start] not prepared');
      return;
    }
    if (sampleRate != sampleRate8k && sampleRate != sampleRate16k) {
      throw ArgumentError('Invalid sample rate');
    }
    _sampleRate = sampleRate;
    _nativeMediaChat.setAudioSampleRate(sampleRate);
    if (_androidHardwareAecEnabled) {
      await _setAndroidPlayerVoiceCommunication(true);
    }
    if (Platform.isIOS) {
      await _iosAudioProcessingUpdate;
      if ((!_iosAudioIoAttached ||
              _iosVoiceProcessingAttached != _iosVoiceProcessingEnabled) &&
          !await _attachIosAudioIO(_iosVoiceProcessingEnabled)) {
        throw StateError('iOS audio IO unavailable');
      }
      if (_iosVoiceProcessingEnabled && !await _setIosVoiceProcessing(true)) {
        Logging.e(_tag, '[start] iOS VoiceProcessingIO unavailable');
        throw StateError('iOS VoiceProcessingIO unavailable');
      }
    }
    _nativeMediaChat.start();
  }

  void destroy() {
    _destroyed = true;
    unawaited(_setAndroidPlayerVoiceCommunication(false));
    if (Platform.isIOS) {
      _scheduleIosVoiceProcessingRelease();
    }
    _nativeMediaChat.destroy();
    _nativeChatChannel.destroy();
  }

  void _scheduleAndroidAudioRecordRebuild(
    bool hardwareAec,
    bool hardwareNs,
    bool hardwareAgc,
    bool restart,
  ) {
    _androidAudioRecordRebuild = _androidAudioRecordRebuild
        .then(
      (_) => _rebuildAndroidAudioRecord(
        hardwareAec,
        hardwareNs,
        hardwareAgc,
        restart,
      ),
    )
        .catchError((Object error) {
      Logging.e(_tag, '[rebuildAndroidAudioRecord] failed: $error');
    });
    unawaited(_androidAudioRecordRebuild);
  }

  Future<void> _rebuildAndroidAudioRecord(
    bool hardwareAec,
    bool hardwareNs,
    bool hardwareAgc,
    bool restart,
  ) async {
    if (!Platform.isAndroid || !_prepared) {
      return;
    }

    Logging.i(
      _tag,
      '[rebuildAndroidAudioRecord] hardwareAec=$hardwareAec '
      'hardwareNs=$hardwareNs hardwareAgc=$hardwareAgc restart=$restart '
      'sampleRate=$_sampleRate',
    );

    if (restart) {
      _nativeMediaChat.stop();
    }
    if (!hardwareAec) {
      await _setAndroidPlayerVoiceCommunication(false);
    }

    final attached = await _PlatformChannel.attachMediaChat(
      _nativeMediaChat.ptr,
      hardwareAec: hardwareAec,
      hardwareNs: hardwareNs,
      hardwareAgc: hardwareAgc,
    );
    if (!attached) {
      Logging.e(
        _tag,
        '[rebuildAndroidAudioRecord] attachMediaChat failed, hardwareAec=$hardwareAec',
      );
      return;
    }

    if (!restart) {
      return;
    }

    _nativeMediaChat.setAudioSampleRate(_sampleRate);
    if (hardwareAec) {
      await _setAndroidPlayerVoiceCommunication(true);
    }
    _nativeMediaChat.start();
  }

  Future<void> _setAndroidPlayerVoiceCommunication(bool enable) async {
    final playbackPlayer = _playbackPlayer;
    if (playbackPlayer == null || !Platform.isAndroid) {
      return;
    }
    if (_androidPlayerVoiceCommunicationEnabled == enable) {
      return;
    }

    _androidPlayerVoiceCommunicationEnabled = enable;
    try {
      final success = await _PlatformChannel.setAndroidPlayerVoiceCommunication(
        playbackPlayer._nativeMediaPlayer.ptr,
        enable,
        playbackPlayer._nativeMediaPlayer.outputToken,
      );
      if (!success) {
        _androidPlayerVoiceCommunicationEnabled = !enable;
        Logging.e(_tag, '[setAndroidPlayerVoiceCommunication] failed');
      }
    } catch (e) {
      _androidPlayerVoiceCommunicationEnabled = !enable;
      Logging.e(_tag, '[setAndroidPlayerVoiceCommunication] failed: $e');
    }
  }

  void _scheduleIosAudioProcessingUpdate(
    int coreNsLevel,
    int coreAecLevel,
    int coreAgcLevel,
    bool voiceProcessing,
    bool restartChat,
  ) {
    _iosAudioProcessingUpdate = _iosAudioProcessingUpdate.then((_) async {
      if (_destroyed) return;
      if (restartChat) {
        _nativeMediaChat.stop();
      }
      if (!voiceProcessing) {
        await _setIosVoiceProcessing(false);
      }
      if (_prepared &&
          (!_iosAudioIoAttached ||
              _iosVoiceProcessingAttached != voiceProcessing) &&
          !await _attachIosAudioIO(voiceProcessing)) {
        Logging.e(
          _tag,
          '[configureAudioProcessing] iOS audio IO rebuild failed, voiceProcessing=$voiceProcessing',
        );
        return;
      }
      if (_destroyed) return;
      _nativeMediaChat.configureAudioProcessing(
        coreNsLevel,
        voiceProcessing ? 0 : coreAecLevel,
        coreAgcLevel,
      );
      if (!restartChat) return;

      _nativeMediaChat.setAudioSampleRate(_sampleRate);
      if (voiceProcessing && !await _setIosVoiceProcessing(true)) {
        Logging.e(
          _tag,
          '[configureAudioProcessing] iOS VoiceProcessingIO unavailable, coreAec=0',
        );
        return;
      }
      _nativeMediaChat.start();
    }).catchError((Object error) {
      Logging.e(_tag, '[configureAudioProcessing] iOS update failed: $error');
    });
    unawaited(_iosAudioProcessingUpdate);
  }

  void _scheduleIosVoiceProcessingRelease() {
    _iosAudioProcessingUpdate = _iosAudioProcessingUpdate.then((_) async {
      await _setIosVoiceProcessing(false);
    }).catchError((Object error) {
      Logging.e(_tag, '[setIosVoiceProcessing] release failed: $error');
    });
    unawaited(_iosAudioProcessingUpdate);
  }

  Future<bool> _attachIosAudioIO(bool voiceProcessing) async {
    if (!Platform.isIOS) return true;
    if (_iosAudioIoAttached && _iosVoiceProcessingAttached == voiceProcessing) {
      return true;
    }

    final playbackPlayer = _playbackPlayer;
    final bindPlayerAudio = voiceProcessing || _iosVoiceProcessingAttached;
    if (bindPlayerAudio && playbackPlayer == null) {
      Logging.e(
        _tag,
        '[attachIosAudioIO] playback player required, voiceProcessing=$voiceProcessing',
      );
      return false;
    }

    final restartPlayer = bindPlayerAudio && playbackPlayer!._started;
    if (restartPlayer) {
      playbackPlayer._nativeMediaPlayer.stop();
    }
    try {
      final attached = await _PlatformChannel.attachMediaChat(
        _mediaChatPtr,
        iosVoiceProcessing: voiceProcessing,
        playbackPlayerPtr:
            bindPlayerAudio ? playbackPlayer!._nativeMediaPlayer.ptr : null,
      );
      if (attached) {
        _iosAudioIoAttached = true;
        _iosVoiceProcessingAttached = voiceProcessing;
      }
      Logging.i(
        _tag,
        '[attachIosAudioIO] backend=${voiceProcessing ? "voice_processing_io" : "audio_queue"} '
        'restartPlayer=$restartPlayer success=$attached',
      );
      return attached;
    } finally {
      if (restartPlayer) {
        playbackPlayer._nativeMediaPlayer.start();
      }
    }
  }

  Future<bool> _setIosVoiceProcessing(bool enable) async {
    if (!Platform.isIOS || _iosVoiceProcessingActive == enable) {
      return true;
    }
    try {
      final success = await _PlatformChannel.setIosVoiceProcessing(
        _mediaChatPtr,
        enable,
      );
      if (success) {
        _iosVoiceProcessingActive = enable;
      }
      Logging.i(
        _tag,
        '[setIosVoiceProcessing] requested=$enable actual=$_iosVoiceProcessingActive success=$success',
      );
      return success;
    } catch (error) {
      Logging.e(_tag, '[setIosVoiceProcessing] failed: $error');
      return false;
    }
  }

  static MediaChat create(Pipe pipe, {Player? playbackPlayer}) {
    final nativeMediaChat = RapidNativeMediaChat();
    nativeMediaChat.create();

    final nativeChatChannel = RapidNativeChatChannel(pipe._nativePipe);
    nativeChatChannel.create();

    return MediaChat._(nativeMediaChat, nativeChatChannel, playbackPlayer);
  }
}

class IntercomAudioProcessingConfig {
  final int nsLevel;
  final int aecLevel;
  final int agcLevel;

  const IntercomAudioProcessingConfig({
    this.nsLevel = 0,
    this.aecLevel = 0,
    this.agcLevel = 0,
  });
}
