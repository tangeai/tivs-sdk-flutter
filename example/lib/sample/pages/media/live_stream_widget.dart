part of '../rapid_kit_sample_pages.dart';

class LiveStreamWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final bool lan;
  final String? deviceAbilities;
  final bool active;
  final Function(bool)? onFullScreenChanged;

  const LiveStreamWidget({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    required this.lan,
    this.deviceAbilities,
    this.active = false,
    this.onFullScreenChanged,
  });

  @override
  State<LiveStreamWidget> createState() => _LiveStreamWidgetState();
}

class _LiveStreamWidgetState extends State<LiveStreamWidget>
    with AutomaticKeepAliveClientMixin {
  final String _tag = '_live_stream_widget';

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

  bool _chatStarted = false;
  bool _streamStarted = false;
  bool _audioMuted = false;
  bool _videoCapturing = false;
  bool _actualRendering = false;
  bool _showBuffering = false;
  bool _establishFailed = false;
  bool _localStorageExist = false;

  Timer? _bufferingDelayTimer;

  bool _recording = false;
  Timer? _recordElapsedTimer;
  int _recordElapsedSeconds = 0;
  int _lastRecordElapsedLogSecond = -1;
  late final MediaDumpController _dumpController;
  bool _isFullScreen = false;

  String _connectionState = 'unknown';

  void _log(String message) {
    Logging.i(_tag, '[device=$_deviceId] $message');
  }

  void _logStreamState(String event, {String extra = ''}) {
    final suffix = extra.isEmpty ? '' : ', $extra';
    _log(
      '$event, streamStarted=$_streamStarted, actualRendering=$_actualRendering, showBuffering=$_showBuffering, establishFailed=$_establishFailed, pipeEstablished=${_pipe.isEstablished}$suffix',
    );
  }

  @override
  void initState() {
    super.initState();

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;
    _cameraCount = widget.cameraCount;
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
    _logStreamState('dispose_requested');
    _bufferingDelayTimer?.cancel();
    _resetRecordElapsedState();
    _dumpController.forceStopIfNeeded('dispose', notifyStateChanged: false);
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
    _logStreamState('start_requested');
    if (_lan) {
      switch (LiveStreamLanStartPolicy.resolve(
        pipeEstablished: _pipe.isEstablished,
        streamStarted: _streamStarted,
      )) {
        case LiveStreamLanStartAction.establishPipe:
          _logStreamState(
            'pipe_establish_requested',
            extra: 'caller=start_lan',
          );
          _pipe.establish();
          return;
        case LiveStreamLanStartAction.startPlayers:
          _startAllPlayers();
          _streamStarted = true;
          _logStreamState('start_applied', extra: 'caller=lan_ready');
          return;
        case LiveStreamLanStartAction.none:
          _logStreamState('start_skipped', extra: 'reason=already_started');
          return;
      }
    }

    if (!_pipe.isEstablished) {
      _logStreamState('pipe_establish_requested', extra: 'caller=start');
      _pipe.establish();
    }

    if (_streamStarted) {
      _logStreamState('start_skipped', extra: 'reason=already_started');
      return;
    }

    _startAllPlayers();
    _streamStarted = true;
    _logStreamState('start_applied', extra: 'caller=start');
  }

  void stop() {
    _logStreamState('stop_requested');
    _bufferingDelayTimer?.cancel();
    _dumpController.forceStopIfNeeded('stop', notifyStateChanged: false);
    if (!_streamStarted) {
      _logStreamState('stop_skipped', extra: 'reason=already_stopped');
      _chatSession.stopOnPause();
      setState(() {
        _chatStarted = false;
        _recording = false;
        _videoCapturing = false;
        _resetRecordElapsedState();
      });
      return;
    }

    _stopAllPlayers();
    _streamStarted = false;
    _logStreamState('stop_applied', extra: 'caller=stop');
    _chatSession.stopOnPause();
    setState(() {
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

  Widget _root() => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _top(),
          if (!_isFullScreen)
            Positioned(left: 0, right: 0, bottom: 0, child: _controlsPanel()),
        ],
      );

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
    setState(() => _isFullScreen = !_isFullScreen);
    setFullScreenOrientation(_isFullScreen);
    setFullScreenSystemUI(_isFullScreen);
    widget.onFullScreenChanged?.call(_isFullScreen);
  }

  void _onVolumeTap() {
    mute();
    setState(() => _audioMuted = _playerCamera0.isMute());
  }

  void _onQualitySwitchChanged(bool value) {
    setState(() => _isHighQuality = value);
    _saveQualityPreference(value);

    if (_pipe.isEstablished) {
      _applyQualityPreference();
    }
  }

  Future<void> _loadQualityPreference() async {
    final value = await SharedPreferencesUtil.instance.getInt(
      SampleConstants.storageKeyLiveStreamQuality,
    );
    if (!mounted) return;

    final isHighQuality = value == SampleConstants.switchOnValue;
    if (_isHighQuality != isHighQuality) {
      setState(() => _isHighQuality = isHighQuality);
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

    if (ret && ret1 && ret2) {
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
      if (!mounted) return;

      if (ret && ret1 && ret2) {
        SnackTips.show(context, '录像保存成功.');
      } else {
        SnackTips.show(context, '录像保存失败.');
      }
      setState(() {
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
      if (!mounted) return;
      if (!ret || !ret1 || !ret2) {
        await _stopStartedRecorders(ret, ret1, ret2);
        if (!mounted) return;
        SnackTips.show(context, '录像启动失败.');
        setState(() {
          _recording = false;
          _videoCapturing = false;
          _resetRecordElapsedState();
        });
        return;
      }
      SnackTips.show(context, '开始录像...');
      setState(() {
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
        'record_duration_elapsed_changed',
        durations,
        elapsedSeconds,
      );
      setState(() => _recordElapsedSeconds = elapsedSeconds);
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

  Future<void> _stopStartedRecorders(
    bool camera0Started,
    bool camera1Started,
    bool camera2Started,
  ) async {
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
    final chatStarted = _chatSession.started;
    setState(() {
      _audioMuted = _playerCamera0.isMute();
      _chatStarted = chatStarted;
    });
    return chatStarted;
  }

  Future<void> _onChatPressEnd() async {
    if (!_chatSession.usePushToTalk) return;
    await _chatSession.pressToTalkEnd();
    final chatStarted = _chatSession.started;
    setState(() {
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

  Widget _playerFrame() {
    final List<Widget> players = [];
    if (!_pureAudioMode) {
      players.add(textureOfCamera0());
      if (existCamera1()) players.add(textureOfCamera1());
      if (existCamera2()) players.add(textureOfCamera2());
    }

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
          child: buildBottomOverlayTools(
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
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ObsWidget(deviceId: _deviceId),
              const SizedBox(height: 4),
              RenderPerfWidget(
                player: _playerCamera0,
                pipe: _pipe,
                liveStream: _primaryStream,
              ),
            ],
          ),
        ),
    ];
  }

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

    final chatStarted = _chatSession.started;
    setState(() {
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
      if (!mounted || !resp.success) return;
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
    if (!mounted) return;
    final level = storedLevel == AudioProcessingDefaults.unsetLevel
        ? SampleConstants.defaultAudioIntercomAecLevel
        : storedLevel.clamp(0, 2);
    SampleConstants.intercomAecEnabled = level != 0;
  }

  void _handleRenderStateChange(bool isRendering) {
    if (_pureAudioMode) {
      _bufferingDelayTimer?.cancel();
      if (!_actualRendering || _showBuffering) {
        setState(() {
          _actualRendering = true;
          _showBuffering = false;
        });
      }
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
        setState(() => _showBuffering = false);
      } else if (previousRendering != isRendering) {
        setState(() {});
      }
    } else {
      if (previousRendering != isRendering) {
        setState(() {});
      }
      _bufferingDelayTimer?.cancel();
      _bufferingDelayTimer = Timer(const Duration(seconds: 10), () {
        if (!_actualRendering && mounted) {
          setState(() => _showBuffering = true);
        }
      });
    }
  }

  void _querySdCardState() async {
    final resp = await InstructStandard.storageState(_pipe);
    if (!mounted) return;
    if (!resp.success) return;
    final total = resp.data?.total ?? 0;
    setState(() => _localStorageExist = total > 0);
  }

  void _onLocalReplayTap() {
    if (!_localStorageExist) {
      SnackTips.show(context, '设备没有存储卡！');
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
    _secondaryStream?.highQuality();
  }

  void setLowQuality() {
    _primaryStream.lowQuality();
    _secondaryStream?.lowQuality();
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

  void _startAllPlayers() {
    _logStreamState('start_all_players');
    if (_pureAudioMode) {
      _bufferingDelayTimer?.cancel();
      _actualRendering = true;
      _showBuffering = false;
    }
    _playerCamera0.start();
    _playerCamera1?.start();
    _playerCamera2?.start();
    _primaryStream.start();
    _secondaryStream?.start();
  }

  void _stopAllPlayers() {
    _logStreamState('stop_all_players');
    _playerCamera0.stop();
    _playerCamera1?.stop();
    _playerCamera2?.stop();
    _primaryStream.stop();
    _secondaryStream?.stop();
  }

  void _disposeAllPlayers() {
    _logStreamState('dispose_all_players');
    _playerCamera0.destroy();
    _playerCamera1?.destroy();
    _playerCamera2?.destroy();
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
      _connectionState = state.name;
      _logStreamState('pipe_state', extra: 'state=${state.name}');
      if (state == PipeState.established) {
        _applyQualityPreference();

        if (_lan && widget.active && !_streamStarted) {
          _startAllPlayers();
          _streamStarted = true;
          _logStreamState(
            'start_applied',
            extra: 'caller=pipe_established_lan',
          );
        }

        if (_features == null) {
          _queryAbilities();
          _querySdCardState();
        }
      } else if (state == PipeState.attempting) {
        setState(() => _establishFailed = false);
      } else {
        setState(() => _establishFailed = true);
      }
    });

    if (_pipe.isEstablished && _features == null) _queryAbilities();
  }

  void _prepareMultiplePlayers() {
    _log('prepare_multiple_players');
    _playerCamera0 = _createSamplePlayer();
    _configurePlayerVideoMode(_playerCamera0);
    _playerCamera0.onRenderState = (state) {
      _handleRenderStateChange(state != RenderState.buffering);
    };

    if (!_pureAudioMode && _cameraCount >= 2) {
      _playerCamera1 = _createSamplePlayer();
      _configurePlayerVideoMode(_playerCamera1!);
      _playerCamera1!.bindingPrimaryPlayer(_playerCamera0);
      _playerCamera1!.enableAudio(false);
    }

    if (!_pureAudioMode && _cameraCount >= 3) {
      _playerCamera2 = _createSamplePlayer();
      _configurePlayerVideoMode(_playerCamera2!);
      _playerCamera2!.bindingPrimaryPlayer(_playerCamera0);
      _playerCamera2!.enableAudio(false);
    }

    _primaryStream = LiveStream.createPrimary(
      _pipe,
      enableAudio: _streamAudioEnabled,
    );
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

    _applyQualityPreference();
    setMute(_audioMuted);
  }
}
