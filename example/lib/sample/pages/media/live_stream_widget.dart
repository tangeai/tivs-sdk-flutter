part of '../rapid_kit_sample_pages.dart';

class LiveStreamWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final bool lan;
  final String? deviceAbilities;
  final bool active;
  final Function(bool)? onFullScreenChanged;
  final VoidCallback? onLocalReplayRequested;
  final VoidCallback? onPlaybackReady;

  const LiveStreamWidget({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    required this.lan,
    this.deviceAbilities,
    this.active = false,
    this.onFullScreenChanged,
    this.onLocalReplayRequested,
    this.onPlaybackReady,
  });

  @override
  State<LiveStreamWidget> createState() => _LiveStreamWidgetState();
}

class _LiveStreamWidgetState extends State<LiveStreamWidget>
    with AutomaticKeepAliveClientMixin {
  final String _tag = '_live_stream_widget';
  static const Duration _secondaryStartDelay = Duration(milliseconds: 500);

  late String _deviceId;
  late String _deviceName;
  late int _cameraCount;
  late bool _lan;
  late bool _pureAudioMode;
  late bool _streamAudioEnabled;

  Map<String, dynamic>? _features;
  bool _abilitiesQueryInFlight = false;

  bool _isHighQuality = false;

  late Pipe _pipe;

  late ChatSession _chatSession;

  late LiveStream _primaryStream;
  LiveStream get primaryStream => _primaryStream;
  LiveStream? _secondaryStream;

  late Player _playerCamera0;
  Player? _playerCamera1;
  Player? _playerCamera2;
  Player? _playerCamera3;

  bool _chatStarted = false;
  bool _streamStarted = false;
  bool _secondaryStreamStarted = false;
  bool _primaryPlaybackReadyNotified = false;
  bool _audioMuted = false;
  bool _videoCapturing = false;
  bool _actualRendering = false;
  bool _showBuffering = false;
  bool _establishFailed = false;
  bool _localStorageExist = false;

  Timer? _bufferingDelayTimer;
  Timer? _secondaryStartTimer;

  bool _recording = false;
  Timer? _recordElapsedTimer;
  int _recordElapsedSeconds = 0;
  int _lastRecordElapsedLogSecond = -1;
  late final MediaDumpController _dumpController;
  bool _isFullScreen = false;
  bool _disposed = false;
  late final List<bool> _playerReady;

  String _connectionState = 'unknown';

  bool get _canUpdateUi => mounted && !_disposed;

  void _setStateIfMounted(VoidCallback fn) {
    if (!_canUpdateUi) {
      return;
    }
    setState(fn);
  }

  void _log(String message) {
    Logging.i(_tag, '[device=$_deviceId] $message');
  }

  void _logStreamState(String event, {String extra = ''}) {
    final suffix = extra.isEmpty ? '' : ', $extra';
    _log(
        '$event, streamStarted=$_streamStarted, secondaryStreamStarted=$_secondaryStreamStarted, primaryPlaybackReadyNotified=$_primaryPlaybackReadyNotified, actualRendering=$_actualRendering, showBuffering=$_showBuffering, establishFailed=$_establishFailed, pipeEstablished=${_pipe.isEstablished}$suffix');
  }

  @override
  void initState() {
    super.initState();

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;
    _cameraCount = widget.cameraCount;
    _playerReady = List.filled(_cameraCount, false);
    _lan = widget.lan;
    _pureAudioMode = SampleConstants.pureAudioModeEnabled;
    _streamAudioEnabled =
        DeviceAudioCapability.streamAudioEnabledFromDeviceAbilities(
      widget.deviceAbilities,
    );
    _applyDefaultIntercomAecLevelFromDeviceAbilities(widget.deviceAbilities);

    _showBuffering = false;

    _log(
      'initState, lan=$_lan, cameraCount=$_cameraCount, pureAudioMode=$_pureAudioMode, streamAudioEnabled=$_streamAudioEnabled',
    );
    _prepareComponents();
    _loadQualityPreference();
    _dumpController = MediaDumpController(
      context: () => context,
      mounted: () => mounted,
      players: _dumpTargets,
      chatSessions: _dumpChatTargets,
      log: _log,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    if (widget.active) {
      start();
    } else {
      _primaryStream.stop();
      _secondaryStream?.stop();
    }
  }

  @override
  void didUpdateWidget(covariant LiveStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.active == widget.active) {
      return;
    }

    _logStreamState('active_changed', extra: 'active=${widget.active}');
    if (widget.active) {
      start();
    } else {
      stop();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _logStreamState('dispose_requested');
    _pipe.listen((_) {});
    _playerCamera0.onRenderState = (_) {};
    _playerCamera1?.onRenderState = (_) {};
    _playerCamera2?.onRenderState = (_) {};
    _playerCamera3?.onRenderState = (_) {};
    _bufferingDelayTimer?.cancel();
    _cancelSecondaryStart();
    _resetRecordElapsedState();
    _dumpController.forceStopIfNeeded('dispose', notifyStateChanged: false);
    if (_streamStarted || _secondaryStreamStarted) {
      _stopAllPlayers();
    }
    _disposeAllPlayers();
    _pipe.abolish();
    _pipe.destroy();
    _chatSession.destroy();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void start() {
    if (_disposed) {
      return;
    }
    _logStreamState('start_requested');
    _prepareLiveStartup();
    _logStreamState('pipe_establish_requested', extra: 'caller=start');
    _pipe.establish();
    final pipeState = _pipe.currentState();
    switch (LiveStreamStartPolicy.resolve(
      pipeEstablished: pipeState == PipeState.established,
      pipeAttempting: pipeState == PipeState.attempting,
      primaryStarted: _streamStarted,
    )) {
      case LiveStreamStartAction.establishPipe:
        return;
      case LiveStreamStartAction.waitForPipe:
        _logStreamState('start_skipped', extra: 'reason=pipe_attempting');
        return;
      case LiveStreamStartAction.startPrimary:
        _startPrimaryPlayback(caller: 'start_pipe_ready');
        return;
      case LiveStreamStartAction.none:
        _logStreamState('start_skipped', extra: 'reason=already_started');
        return;
    }
  }

  void stop() {
    if (_disposed) {
      return;
    }
    _logStreamState('stop_requested');
    _bufferingDelayTimer?.cancel();
    _cancelSecondaryStart();
    _dumpController.forceStopIfNeeded('stop', notifyStateChanged: false);
    if (!_streamStarted && !_secondaryStreamStarted) {
      _primaryStream.stop();
      _secondaryStream?.stop();
      _logStreamState('stop_skipped', extra: 'reason=already_stopped');
      _chatSession.stopOnPause();
      _setStateIfMounted(() {
        _chatStarted = false;
        _recording = false;
        _videoCapturing = false;
        _resetRecordElapsedState();
      });
      return;
    }

    _stopAllPlayers();
    _logStreamState('stop_applied', extra: 'caller=stop');
    _chatSession.stopOnPause();
    _setStateIfMounted(() {
      _chatStarted = false;
      _recording = false;
      _videoCapturing = false;
      _resetRecordElapsedState();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Semantics(
      key: const ValueKey('rapid-live-render-state'),
      label: 'rapid-live-render-state',
      value: _actualRendering ? 'rendering=true' : 'rendering=false',
      child: _root(),
    );
  }

  Widget _root() {
    if (_cameraCount == 4 && !_pureAudioMode) {
      return ColoredBox(
        color: SampleThemeConfigure.colorVideoBackground,
        child: FourCameraLiveFrame(
          isFullScreen: _isFullScreen,
          diagnostics: _diagnostics(),
          tools: _bottomOverlayTools(),
          controls: _isFullScreen ? _operationOfFullScreen() : _controlsPanel(),
          players: Stack(
            fit: StackFit.expand,
            children: [
              _playerBackground(),
              _buildPlayers(_cameraTextures()),
              if (_showBuffering && !_establishFailed) createBufferingWidget(),
              if (_establishFailed) _establishFailedWidget(),
            ],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _top(),
        if (!_isFullScreen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _controlsPanel(),
          ),
      ],
    );
  }

  Widget _controlsPanel() => _buildMiddleControls(
        _audioMuted,
        _videoCapturing,
        _recordElapsedSeconds,
        _isFullScreen,
        _onVolumeTap,
        _onCapture,
        _onRecordTap,
        _onLocalReplayTap,
        _toggleFullScreen,
      );

  Widget _operationOfFullScreen() => _buildOperationOfFullScreen(
        _audioMuted,
        _videoCapturing,
        _recordElapsedSeconds,
        _toggleFullScreen,
        _onVolumeTap,
        _onCapture,
        _onRecordTap,
      );

  void _toggleFullScreen() {
    _setStateIfMounted(() => _isFullScreen = !_isFullScreen);
    setFullScreenOrientation(_isFullScreen);
    setFullScreenSystemUI(_isFullScreen);
    widget.onFullScreenChanged?.call(_isFullScreen);
  }

  void _onVolumeTap() {
    mute();
    _setStateIfMounted(() => _audioMuted = _playerCamera0.isMute());
  }

  void _onQualitySwitchChanged(bool value) {
    _setStateIfMounted(() => _isHighQuality = value);
    _saveQualityPreference(value);

    if (_pipe.isEstablished) {
      _applyQualityPreference();
    }
  }

  Future<void> _loadQualityPreference() async {
    final value = await SharedPreferencesUtil.instance
        .getInt(SampleConstants.storageKeyLiveStreamQuality);
    if (!_canUpdateUi) return;

    final isHighQuality = value == SampleConstants.switchOnValue;
    if (_isHighQuality != isHighQuality) {
      _setStateIfMounted(() => _isHighQuality = isHighQuality);
    }
    _applyQualityPreference();
  }

  Future<void> _saveQualityPreference(bool isHighQuality) async {
    await SharedPreferencesUtil.instance.setInt(
      SampleConstants.storageKeyLiveStreamQuality,
      isHighQuality
          ? SampleConstants.switchOnValue
          : SampleConstants.switchOffValue,
    );
  }

  void _applyQualityPreference() {
    if (!LiveStreamQualityApplyPolicy.shouldApply(
      pureAudioMode: _pureAudioMode,
      pipeEstablished: _pipe.isEstablished,
      primaryStarted: _streamStarted,
      primaryPlaybackReady: _primaryPlaybackReadyNotified,
    )) {
      _logStreamState(
        'quality_apply_skipped',
        extra: 'reason=primary_not_ready',
      );
      return;
    }
    _isHighQuality ? setHighQuality() : setLowQuality();
  }

  void _onCapture() async {
    final granted = await RuntimePermissions.accessGranted(
      PermissionType.gallery,
    );
    if (!granted) {
      final ret = await RuntimePermissions.requestAccess(
        PermissionType.gallery,
      );
      if (ret == PermissionState.denied) {
        SnackTips.show(context, '请到系统设置中，手动授权访问相册.');
      } else {
        SnackTips.show(context, '请授权访问相册.');
      }
      return;
    }

    final ret = await _playerCamera0.capture();
    final ret1 = await _playerCamera1?.capture() ?? true;
    final ret2 = await _playerCamera2?.capture() ?? true;
    final ret3 = await _playerCamera3?.capture() ?? true;

    if (ret && ret1 && ret2 && ret3) {
      SnackTips.show(context, '截图保存成功.');
    } else {
      SnackTips.show(context, '截图保存失败.');
    }
  }

  void _onRecordTap() async {
    final granted = await RuntimePermissions.accessGranted(
      PermissionType.gallery,
    );
    if (!granted) {
      final ret = await RuntimePermissions.requestAccess(
        PermissionType.gallery,
      );
      if (ret == PermissionState.denied) {
        SnackTips.show(context, '请到系统设置中，手动授权访问相册.');
      } else {
        SnackTips.show(context, '请授权访问相册.');
      }
      return;
    }

    if (_recording) {
      final ret = await _playerCamera0.stopRecord();
      final ret1 = await _playerCamera1?.stopRecord() ?? true;
      final ret2 = await _playerCamera2?.stopRecord() ?? true;
      final ret3 = await _playerCamera3?.stopRecord() ?? true;
      if (!_canUpdateUi) return;

      if (ret && ret1 && ret2 && ret3) {
        SnackTips.show(context, '录像保存成功.');
      } else {
        SnackTips.show(context, '录像保存失败.');
      }
      _setStateIfMounted(() {
        _recording = false;
        _videoCapturing = false;
        _resetRecordElapsedState();
      });
    } else {
      final ret = await _playerCamera0.startRecord();
      final ret1 =
          _playerCamera1 == null ? true : await _playerCamera1!.startRecord();
      final ret2 =
          _playerCamera2 == null ? true : await _playerCamera2!.startRecord();
      final ret3 =
          _playerCamera3 == null ? true : await _playerCamera3!.startRecord();
      if (!_canUpdateUi) return;
      if (!ret || !ret1 || !ret2 || !ret3) {
        await _stopStartedRecorders(ret, ret1, ret2, ret3);
        if (!_canUpdateUi) return;
        SnackTips.show(context, '录像启动失败.');
        _setStateIfMounted(() {
          _recording = false;
          _videoCapturing = false;
          _resetRecordElapsedState();
        });
        return;
      }
      SnackTips.show(context, '开始录像...');
      _setStateIfMounted(() {
        _recording = true;
        _videoCapturing = true;
        _startRecordElapsedTimer();
      });
    }
  }

  void _startRecordElapsedTimer() {
    _recordElapsedTimer?.cancel();
    final initialDurations = _recordDurationSnapshotMs();
    final initialDurationMs = _maxRecordDurationMs(initialDurations);
    _recordElapsedSeconds =
        LiveRecordUiHelpers.elapsedSecondsFromRecordDurationMs(
      initialDurationMs,
    );
    _lastRecordElapsedLogSecond = -1;
    _logRecordDurationSnapshot(
      'record_duration_timer_started',
      initialDurations,
      _recordElapsedSeconds,
    );
    _recordElapsedTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (!mounted || !_recording) {
        _log(
          'record_duration_timer_cancelled, mounted=$mounted, recording=$_recording, elapsed_s=$_recordElapsedSeconds',
        );
        timer.cancel();
        return;
      }
      final durations = _recordDurationSnapshotMs();
      final elapsedSeconds =
          LiveRecordUiHelpers.elapsedSecondsFromRecordDurationMs(
        _maxRecordDurationMs(durations),
      );
      if (elapsedSeconds == _recordElapsedSeconds) {
        return;
      }
      _logRecordDurationSnapshot(
          'record_duration_elapsed_changed', durations, elapsedSeconds);
      _setStateIfMounted(() => _recordElapsedSeconds = elapsedSeconds);
    });
  }

  List<int> _recordDurationSnapshotMs() {
    final durations = <int>[_playerCamera0.recordDurationMs()];
    final playerCamera1 = _playerCamera1;
    if (playerCamera1 != null) {
      durations.add(playerCamera1.recordDurationMs());
    }
    final playerCamera2 = _playerCamera2;
    if (playerCamera2 != null) {
      durations.add(playerCamera2.recordDurationMs());
    }
    final playerCamera3 = _playerCamera3;
    if (playerCamera3 != null) {
      durations.add(playerCamera3.recordDurationMs());
    }
    return durations;
  }

  int _maxRecordDurationMs(List<int> durations) {
    return durations.fold<int>(
      0,
      (maxDuration, duration) => math.max(maxDuration, duration),
    );
  }

  void _logRecordDurationSnapshot(
    String event,
    List<int> durations,
    int elapsedSeconds,
  ) {
    if (elapsedSeconds == _lastRecordElapsedLogSecond && elapsedSeconds != 0) {
      return;
    }
    _lastRecordElapsedLogSecond = elapsedSeconds;
    _log(
      '$event, elapsed_s=$elapsedSeconds, camera_duration_ms=${durations.join('/')}',
    );
  }

  Future<void> _stopStartedRecorders(bool camera0Started, bool camera1Started,
      bool camera2Started, bool camera3Started) async {
    if (camera0Started) {
      await _playerCamera0.stopRecordToFile();
    }
    final playerCamera1 = _playerCamera1;
    if (camera1Started && playerCamera1 != null) {
      await playerCamera1.stopRecordToFile();
    }
    final playerCamera2 = _playerCamera2;
    if (camera2Started && playerCamera2 != null) {
      await playerCamera2.stopRecordToFile();
    }
    final playerCamera3 = _playerCamera3;
    if (camera3Started && playerCamera3 != null) {
      await playerCamera3.stopRecordToFile();
    }
  }

  void _resetRecordElapsedState() {
    if (_recordElapsedTimer != null || _recordElapsedSeconds != 0) {
      _log('record_duration_timer_reset, elapsed_s=$_recordElapsedSeconds');
    }
    _recordElapsedTimer?.cancel();
    _recordElapsedTimer = null;
    _recordElapsedSeconds = 0;
    _lastRecordElapsedLogSecond = -1;
  }

  List<Player> _dumpTargets() {
    return [
      _playerCamera0,
      if (_playerCamera1 != null) _playerCamera1!,
      if (_playerCamera2 != null) _playerCamera2!,
      if (_playerCamera3 != null) _playerCamera3!,
    ];
  }

  List<MediaDumpSender> _dumpChatTargets() {
    return [_chatSession];
  }

  Widget _buildDumpActionButton() {
    return _dumpController.buildActionButton(
      canStart: _streamStarted && _pipe.isEstablished && !_establishFailed,
      unavailableMessage: '播放尚未就绪',
    );
  }

  void _onChatTap() async {
    await _onIntercomTap();
  }

  Future<bool> _onChatPressStart() async {
    if (!_chatSession.usePushToTalk) return false;
    await _chatSession.pressToTalkStart();
    if (!_canUpdateUi) return false;
    final chatStarted = _chatSession.started;
    _setStateIfMounted(() {
      _audioMuted = _playerCamera0.isMute();
      _chatStarted = chatStarted;
    });
    return chatStarted;
  }

  Future<void> _onChatPressEnd() async {
    if (!_chatSession.usePushToTalk) return;
    await _chatSession.pressToTalkEnd();
    if (!_canUpdateUi) return;
    final chatStarted = _chatSession.started;
    _setStateIfMounted(() {
      _audioMuted = _playerCamera0.isMute();
      _chatStarted = chatStarted;
    });
  }

  Widget _top() => Container(
        color: SampleThemeConfigure.colorVideoBackground,
        child: _playerFrame(),
      );

  Widget _qualitySwitch() => _pureAudioMode
      ? const SizedBox.shrink()
      : _buildQualitySwitch(_isHighQuality, _onQualitySwitchChanged);

  Widget _audioConfigOverlayPanel() {
    return Tooltip(
      message: '音频配置',
      child: InkWell(
        onTap: _onAudioConfigTap,
        borderRadius: BorderRadius.circular(
          kBottomOverlayIntercomPillHeight / 2,
        ),
        child: Container(
          height: kBottomOverlayIntercomPillHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(140),
            borderRadius: BorderRadius.circular(
              kBottomOverlayIntercomPillHeight / 2,
            ),
            border: Border.all(
              color: Colors.white.withAlpha(41),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.tune_rounded, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                '音频配置',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cameraTextures() {
    final List<Widget> players = [];
    if (!_pureAudioMode) {
      players.add(textureOfCamera0());
      if (existCamera1()) players.add(textureOfCamera1());
      if (existCamera2()) players.add(textureOfCamera2());
      if (_playerCamera3 != null) players.add(_playerCamera3!.texture());
    }
    return players;
  }

  Widget _playerFrame() {
    final players = _cameraTextures();
    return Stack(
      fit: StackFit.expand,
      children: [
        _playerBackground(),
        if (players.isNotEmpty)
          Positioned.fill(child: ClipRect(child: _buildPlayers(players))),
        if (_pureAudioMode) _pureAudioModeHint(),
        if (_showBuffering && !_establishFailed) createBufferingWidget(),
        if (_establishFailed) _establishFailedWidget(),
        ..._buildOverlays(),
      ],
    );
  }

  Widget _buildPlayers(List<Widget> players) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return buildLivePlayersLayout(
          players,
          isFullScreen: _isFullScreen,
          size: constraints.biggest,
        );
      },
    );
  }

  List<Widget> _buildOverlays() {
    return [
      if (!_isFullScreen)
        Positioned(
          left: 16,
          right: 16,
          bottom: 98,
          child: _bottomOverlayTools(),
        ),
      if (_isFullScreen)
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(child: _operationOfFullScreen()),
        ),
      if (!_isFullScreen)
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: _diagnostics(),
        ),
    ];
  }

  Widget _diagnostics() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ObsWidget(deviceId: _deviceId),
          const SizedBox(height: 4),
          RenderPerfWidget(
            player: _playerCamera0,
            pipe: _pipe,
            liveStream: _primaryStream,
          ),
        ],
      );

  Widget _bottomOverlayTools() => buildBottomOverlayTools(
        left: _leftOverlayTools(),
        right: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _audioConfigOverlayPanel(),
            const SizedBox(height: 8),
            buildIntercomPillButton(
              chatStarted: _chatStarted,
              usePushToTalk: _chatSession.usePushToTalk,
              onTapToggle: _onIntercomTap,
              onPressStart: _onChatPressStart,
              onPressEnd: _onChatPressEnd,
            ),
          ],
        ),
      );

  Widget _leftOverlayTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDumpActionButton(),
        const SizedBox(height: 8),
        _qualitySwitch(),
      ],
    );
  }

  Future<void> _onAudioConfigTap() async {
    AudioConfigureOverlay.show(
      context,
      player: _playerCamera0,
      chatSession: _chatSession,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
  }

  Future<void> _onIntercomTap() async {
    if (_chatSession.usePushToTalk) return;
    await _chatSession.toggle();
    if (!_canUpdateUi) return;

    final chatStarted = _chatSession.started;
    _setStateIfMounted(() {
      _audioMuted = _playerCamera0.isMute();
      _chatStarted = chatStarted;
    });
  }

  Widget _pureAudioModeHint() {
    return const Positioned.fill(
      child: Center(
        child: Text(
          '当前为纯音频模式',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Positioned _playerBackground() {
    return Positioned.fill(
      child: Container(
        color: _pureAudioMode
            ? Colors.black
            : SampleThemeConfigure.colorVideoBackground,
      ),
    );
  }

  Widget _establishFailedWidget() {
    return EstablishFailedWidget(
      onRetry: () {
        _logStreamState('retry_clicked');
        setState(() => _establishFailed = false);
        start();
      },
      connectionState: _connectionState,
    );
  }

  void _queryAbilities() async {
    if (_abilitiesQueryInFlight) return;
    _abilitiesQueryInFlight = true;
    try {
      final resp = await InstructStandard.ability(_pipe);
      if (!_canUpdateUi || !resp.success) return;
      _features = resp.data?.features;
      _applyDefaultIntercomAecLevel(_features);
    } finally {
      _abilitiesQueryInFlight = false;
    }
  }

  void _applyDefaultIntercomAecLevelFromDeviceAbilities(
    String? deviceAbilities,
  ) {
    final level =
        AudioProcessingDefaults.defaultIntercomAecLevelFromDeviceAbilities(
      deviceAbilities,
    );
    _setDefaultIntercomAecLevel(level);
    _refreshIntercomAecEnabled();
  }

  void _applyDefaultIntercomAecLevel(Map<String, dynamic>? features) {
    final level = AudioProcessingDefaults.defaultIntercomAecLevel(features);
    _setDefaultIntercomAecLevel(level);
    _refreshIntercomAecEnabled();
  }

  void _setDefaultIntercomAecLevel(int level) {
    final safeLevel = level.clamp(0, 2);
    SampleConstants.defaultAudioIntercomAecLevel = safeLevel;
    SampleConstants.intercomAecEnabled = safeLevel != 0;
  }

  void _refreshIntercomAecEnabled() async {
    final storedLevel = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomAecLevel,
          AudioProcessingDefaults.unsetLevel,
        ) ??
        AudioProcessingDefaults.unsetLevel;
    if (!_canUpdateUi) return;
    final level = storedLevel == AudioProcessingDefaults.unsetLevel
        ? SampleConstants.defaultAudioIntercomAecLevel
        : storedLevel.clamp(0, 2);
    SampleConstants.intercomAecEnabled = level != 0;
  }

  void _handleRenderStateChange(bool isRendering) {
    if (!_canUpdateUi) {
      return;
    }

    if (_pureAudioMode) {
      _bufferingDelayTimer?.cancel();
      if (!_actualRendering || _showBuffering) {
        _setStateIfMounted(() {
          _actualRendering = true;
          _showBuffering = false;
        });
      }
      _notifyPrimaryPlaybackReady();
      return;
    }

    final previousRendering = _actualRendering;
    _actualRendering = isRendering;
    if (previousRendering != isRendering) {
      _logStreamState(
        'render_state_changed',
        extra: 'isRendering=$isRendering',
      );
    }

    if (isRendering) {
      _bufferingDelayTimer?.cancel();
      if (_showBuffering) {
        _setStateIfMounted(() => _showBuffering = false);
      } else if (previousRendering != isRendering) {
        _setStateIfMounted(() {});
      }
    } else {
      if (previousRendering != isRendering) {
        _setStateIfMounted(() {});
      }
      _bufferingDelayTimer?.cancel();
      _bufferingDelayTimer = Timer(const Duration(seconds: 10), () {
        if (!_actualRendering && _canUpdateUi) {
          _setStateIfMounted(() => _showBuffering = true);
        }
      });
    }
  }

  void _querySdCardState() async {
    final resp = await InstructStandard.storageState(_pipe);
    if (!_canUpdateUi) return;
    if (!resp.success) return;
    final total = resp.data?.total ?? 0;
    _setStateIfMounted(() => _localStorageExist = total > 0);
  }

  void _onLocalReplayTap() {
    if (!_localStorageExist) {
      SnackTips.show(context, '设备没有存储卡！');
      return;
    }

    stop();
    _log('pipe.abolish reason=local_replay_handoff');
    _pipe.abolish();
    final onLocalReplayRequested = widget.onLocalReplayRequested;
    if (onLocalReplayRequested != null) {
      onLocalReplayRequested();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalReplayPage(
          deviceId: _deviceId,
          deviceName: _deviceName,
          cameraCount: _cameraCount,
          deviceAbilities: widget.deviceAbilities,
        ),
      ),
    );
  }

  void mute() {
    _playerCamera0.mute(!_playerCamera0.isMute());
    _audioMuted = _playerCamera0.isMute();
  }

  void setMute(bool mute) => _playerCamera0.mute(mute);

  void setHighQuality() {
    _primaryStream.highQuality();
    if (_secondaryStreamStarted) {
      _secondaryStream?.highQuality();
    }
  }

  void setLowQuality() {
    _primaryStream.lowQuality();
    if (_secondaryStreamStarted) {
      _secondaryStream?.lowQuality();
    }
  }

  Widget textureOfCamera0() => _playerCamera0.texture();
  Widget textureOfCamera1() => _playerCamera1?.texture() ?? Container();
  Widget textureOfCamera2() => _playerCamera2?.texture() ?? Container();

  bool existCamera1() => _playerCamera1 != null;
  bool existCamera2() => _playerCamera2 != null;

  void _configurePlayerVideoMode(Player player) {
    if (_pureAudioMode) {
      player.enableVideo(false);
    }
  }

  void _startPrimaryPlayback({required String caller}) {
    if (!widget.active || !_pipe.isEstablished || _streamStarted) {
      _logStreamState(
        'primary_start_skipped',
        extra: 'caller=$caller, active=${widget.active}',
      );
      return;
    }

    _cancelSecondaryStart();
    _playerReady.fillRange(0, _playerReady.length, false);
    _streamStarted = true;
    _secondaryStreamStarted = false;
    _primaryPlaybackReadyNotified = false;
    _bufferingDelayTimer?.cancel();
    _actualRendering = false;
    _showBuffering = false;
    if (_pureAudioMode) {
      _actualRendering = true;
    }
    _playerCamera0.start();
    if (_secondaryStream == null) {
      _playerCamera1?.start();
      _playerCamera2?.start();
      _playerCamera3?.start();
    }
    _primaryStream.start();
    _logStreamState('start_applied', extra: 'caller=$caller, stream=primary');

    if (_secondaryStream != null) {
      _scheduleSecondaryStart();
    }
  }

  void _prepareLiveStartup() {
    _primaryStream.provider();
    _secondaryStream?.provider(cameraIndex: 1);
    _logStreamState('live_startup_prepared');
  }

  void _scheduleSecondaryStart() {
    if (_secondaryStartTimer != null || _secondaryStreamStarted) {
      return;
    }
    _logStreamState(
      'secondary_start_scheduled',
      extra: 'delayMs=${_secondaryStartDelay.inMilliseconds}',
    );
    _secondaryStartTimer = Timer(_secondaryStartDelay, () {
      _secondaryStartTimer = null;
      _startSecondaryPlayback(caller: 'delay_timeout');
    });
  }

  void _startSecondaryPlayback({required String caller}) {
    if (!LiveStreamSecondaryStartPolicy.shouldStart(
      hasIndependentSecondary: _secondaryStream != null,
      active: widget.active && _canUpdateUi,
      pipeEstablished: _pipe.isEstablished,
      primaryStarted: _streamStarted,
      secondaryStarted: _secondaryStreamStarted,
    )) {
      _logStreamState('secondary_start_skipped', extra: 'caller=$caller');
      return;
    }

    _cancelSecondaryStart();
    _secondaryStreamStarted = true;
    _playerCamera1?.start();
    _secondaryStream!.start();
    _logStreamState(
      'secondary_start_applied',
      extra: 'caller=$caller',
    );
  }

  void _cancelSecondaryStart() {
    _secondaryStartTimer?.cancel();
    _secondaryStartTimer = null;
  }

  void _stopAllPlayers() {
    _logStreamState('stop_all_players');
    _bufferingDelayTimer?.cancel();
    _cancelSecondaryStart();
    _playerReady.fillRange(0, _playerReady.length, false);
    _actualRendering = false;
    _showBuffering = false;
    final secondaryWasStarted = _secondaryStreamStarted;
    _streamStarted = false;
    _secondaryStreamStarted = false;
    _primaryPlaybackReadyNotified = false;
    _playerCamera0.stop();
    if (_secondaryStream == null) {
      _playerCamera1?.stop();
      _playerCamera2?.stop();
      _playerCamera3?.stop();
    } else if (secondaryWasStarted) {
      _playerCamera1?.stop();
    }
    _primaryStream.stop();
    _secondaryStream?.stop();
  }

  void _disposeAllPlayers() {
    _logStreamState('dispose_all_players');
    _playerCamera3?.destroy();
    _playerCamera1?.destroy();
    _playerCamera2?.destroy();
    _playerCamera0.destroy();
    _primaryStream.destroy();
    _secondaryStream?.destroy();
  }

  void _prepareMediaChat() {
    _chatSession = ChatSession(
      context: context,
      pipe: _pipe,
      player: _playerCamera0,
      setMute: setMute,
      isPlayerMute: _playerCamera0.isMute,
      enable16k: () => SampleConstants.intercom16kSamplingEnabled,
    );
  }

  void _prepareComponents() {
    _preparePipe();
    _prepareMultiplePlayers();
    _prepareMediaChat();
  }

  void _preparePipe() {
    _log('prepare_pipe');
    _pipe = Pipe.create(_deviceId);
    if (_lan) _pipe.lan();
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);

    _pipe.listen((state) {
      if (!_canUpdateUi) {
        return;
      }
      _connectionState = state.name;
      _logStreamState('pipe_state', extra: 'state=${state.name}');
      if (state == PipeState.established) {
        if (widget.active && !_streamStarted) {
          _startPrimaryPlayback(caller: 'pipe_established');
        }

        if (_features == null) {
          _queryAbilities();
          _querySdCardState();
        }
      } else if (state == PipeState.attempting) {
        _setStateIfMounted(() => _establishFailed = false);
      } else {
        _setStateIfMounted(() => _establishFailed = true);
      }
    });

    if (_pipe.isEstablished && _features == null) _queryAbilities();
  }

  void _prepareMultiplePlayers() {
    _log('prepare_multiple_players');
    _playerCamera0 = _createSamplePlayer();
    _configurePlayerVideoMode(_playerCamera0);
    _configurePlayerRenderState(_playerCamera0, 0, primary: true);

    if (!_pureAudioMode && _cameraCount >= 2) {
      _playerCamera1 = _createSamplePlayer();
      _configurePlayerVideoMode(_playerCamera1!);
      _configurePlayerRenderState(_playerCamera1!, 1);
      _playerCamera1!.bindingPrimaryPlayer(_playerCamera0);
      _playerCamera1!.enableAudio(false);
    }

    if (!_pureAudioMode && _cameraCount >= 3) {
      _playerCamera2 = _createSamplePlayer();
      _configurePlayerVideoMode(_playerCamera2!);
      _configurePlayerRenderState(_playerCamera2!, 2);
      _playerCamera2!.bindingPrimaryPlayer(_playerCamera0);
      _playerCamera2!.enableAudio(false);
    }

    if (!_pureAudioMode && _cameraCount >= 4) {
      _playerCamera3 = _createSamplePlayer();
      _configurePlayerVideoMode(_playerCamera3!);
      _configurePlayerRenderState(_playerCamera3!, 3);
      _playerCamera3!.bindingPrimaryPlayer(_playerCamera0);
      _playerCamera3!.enableAudio(false);
    }

    _primaryStream =
        LiveStream.createPrimary(_pipe, enableAudio: _streamAudioEnabled);
    final provider = _primaryStream.provider();
    if (provider != null) {
      _playerCamera0.prepare(provider);
    }

    if (!_pureAudioMode && _cameraCount == 2) {
      _secondaryStream = LiveStream.createSecondary(_pipe);
      final provider1 = _secondaryStream!.provider(cameraIndex: 1);
      if (provider1 != null) _playerCamera1!.prepare(provider1);
    }

    if (!_pureAudioMode && _cameraCount >= 3) {
      final provider1 = _primaryStream.provider(cameraIndex: 1);
      if (provider1 != null) _playerCamera1!.prepare(provider1);

      final provider2 = _primaryStream.provider(cameraIndex: 2);
      if (provider2 != null) _playerCamera2!.prepare(provider2);
    }

    if (!_pureAudioMode && _cameraCount >= 4) {
      final provider3 = _primaryStream.provider(cameraIndex: 3);
      if (provider3 != null) _playerCamera3!.prepare(provider3);
    }

    _applyQualityPreference();
    setMute(_audioMuted);
  }

  void _configurePlayerRenderState(Player player, int index,
      {bool primary = false}) {
    player.onRenderState = (state) {
      if (!_canUpdateUi) return;
      final rendering = state == RenderState.started;
      _playerReady[index] = rendering;
      if (widget.active && _streamStarted) {
        _handleRenderStateChange(
          LiveStreamRenderPolicy.anyVisiblePlayerRendering(_playerReady),
        );
      }
      if (primary) {
        if (rendering) {
          final firstPrimaryFrame = !_primaryPlaybackReadyNotified;
          _notifyPrimaryPlaybackReady();
          if (_secondaryStream != null) {
            _startSecondaryPlayback(caller: 'primary_first_frame');
          }
          if (firstPrimaryFrame) {
            _applyQualityPreference();
          }
        }
      }
      if (_streamStarted && _playerReady.every((ready) => ready)) {
        _logStreamState('all_players_ready');
      }
    };
  }

  void _notifyPrimaryPlaybackReady() {
    if (!_streamStarted || _primaryPlaybackReadyNotified) {
      return;
    }
    _primaryPlaybackReadyNotified = true;
    _logStreamState('playback_ready', extra: 'source=primary');
    widget.onPlaybackReady?.call();
  }
}
