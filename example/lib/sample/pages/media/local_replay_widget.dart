part of '../rapid_kit_sample_pages.dart';

class LocalReplayPlaybackController {
  _LocalReplayWidgetState? _state;
  bool _active = false;
  bool _disposed = false;

  bool get active => _active;

  void start() {
    if (_disposed) return;
    _active = true;
    _state?._setLifecycleActive(true, reason: 'controller_start');
  }

  void stop() {
    if (_disposed) return;
    _active = false;
    _state?._setLifecycleActive(false, reason: 'controller_stop');
  }

  void _attach(_LocalReplayWidgetState state) {
    if (_disposed) return;
    assert(_state == null || identical(_state, state));
    _state = state;
  }

  void _detach(_LocalReplayWidgetState state) {
    if (identical(_state, state)) _state = null;
  }

  void dispose() {
    if (_disposed) return;
    _active = false;
    _state?._setLifecycleActive(false, reason: 'controller_dispose');
    _state = null;
    _disposed = true;
  }
}

enum _LocalReplayPlaybackState { stopped, starting, running, stopping }

class LocalReplayWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final String? deviceAbilities;
  final bool active;
  final LocalReplayPlaybackController? playbackController;

  /// A valid frame is visible on at least one camera in this transition.
  final VoidCallback? onFirstFramePresented;

  /// Every camera has presented a valid frame in this transition.
  final VoidCallback? onPlaybackReady;

  const LocalReplayWidget({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    this.deviceAbilities,
    this.active = false,
    this.playbackController,
    this.onFirstFramePresented,
    this.onPlaybackReady,
  });

  @override
  State<LocalReplayWidget> createState() => _LocalReplayWidgetState();
}

class _LocalReplayWidgetState extends State<LocalReplayWidget>
    with AutomaticKeepAliveClientMixin {
  static const String _tag = "_LocalReplayWidget_";

  static const Duration _seekDebounceDelay = Duration(milliseconds: 350);
  static const Duration _transitionUiTimeout = Duration(seconds: 20);
  static const Duration _aovTransitionUiTimeout = Duration(seconds: 90);

  late String _deviceId;
  late String _deviceName;
  late int _cameraCount;
  late bool _streamAudioEnabled;
  late bool _isAovDevice;

  bool _audioMuted = false;
  bool _primaryAudioSuppressed = true;
  bool _videoRecording = false;
  bool _eventsLoading = true;
  bool _recordIndexQueryActive = false;
  String? _recordIndexError;
  late final RecordListQuery _recordListQuery;
  bool _establishFailed = false;
  String? _connectionState;

  late Pipe _pipe;
  late LocalReplayStream _stream;
  late Player _player;
  Player? _player1;
  Player? _player2;
  Player? _player3;
  Pipe? _downloadPipe;
  LocalReplayStream? _downloadStream;
  List<LocalReplayCapture> _downloadCaptures = <LocalReplayCapture>[];
  final Set<int> _completedDownloadCameras = <int>{};
  final Map<int, double> _downloadProgress = <int, double>{};
  bool _isDownloading = false;
  Pipe? _downloadStartingPipe;
  bool _downloadStreamStarted = false;
  int? _downloadingRecordTimestamp;
  double _totalDownloadProgress = 0;

  int _currentTimestampInMs = 0;
  int? _timestampLeaderIndex;

  LocalReplaySpeed _speed = LocalReplaySpeed.x1;

  RecordIndexPacket? _recordIndexPacket;
  int _recordIndexRequestGeneration = 0;
  int _recordQueryConnectionGeneration = 0;
  bool _hasSelectedRecord = false;
  bool _selectFirstRecordAfterLoad = true;
  String? _initialRecordMessage;

  DateTime _selectedDate = DateTime.now();

  bool _paused = false;

  bool _loading = true;

  Timer? _seekTimeoutTimer;
  Timer? _seekDebounceTimer;
  bool _transitionCoversTexture = true;
  int _seekUiGeneration = 0;
  int _lifecycleGeneration = 0;
  int _firstFramePresentedGeneration = -1;
  final Stopwatch _visualTransitionClock = Stopwatch();
  late final List<LocalReplayFrameHoldController> _frameHoldControllers;
  late final LocalReplayPresentationState _presentation;
  bool get _transitionActive => _presentation.active;
  int get _visualGeneration => _presentation.generation;
  late LocalReplayBufferingState _bufferingState;
  final Stopwatch _frameArrivalClock = Stopwatch()..start();
  late final MediaDumpController _dumpController;
  _LocalReplayPlaybackState _playbackState = _LocalReplayPlaybackState.stopped;
  bool _lifecycleActive = false;
  bool _pipeOwned = false;
  bool _establishRequested = false;
  bool _pipeSuspendedForRecordQuery = false;
  bool _isDisposing = false;
  bool _uiReady = false;
  int _playbackCommandGeneration = 0;
  bool _forceTextureOnNextStart = false;

  @override
  void initState() {
    super.initState();

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;
    _cameraCount = widget.cameraCount;
    _frameHoldControllers = List.generate(
      _cameraCount,
      (_) => LocalReplayFrameHoldController(),
    );
    _presentation = LocalReplayPresentationState(_cameraCount);
    _isAovDevice =
        LocalReplayUiHelpers.isAovDeviceAbilities(widget.deviceAbilities);
    _bufferingState = LocalReplayBufferingState(
      _cameraCount,
      aovCardReplay: _isAovDevice,
    );
    _log('playback.policy aovCardReplay=$_isAovDevice '
        'nativeBuffering=${_isAovDevice ? 'off' : 'configured'}');
    _streamAudioEnabled =
        DeviceAudioCapability.streamAudioEnabledFromDeviceAbilities(
            widget.deviceAbilities);
    _prepareComponents();
    _recordListQuery = RecordListQuery.shared(_pipe);
    _dumpController = MediaDumpController(
      context: () => context,
      mounted: () => mounted,
      players: _dumpTargets,
      chatSessions: () => const [],
      log: _log,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    widget.playbackController?._attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _uiReady = true;
      final shouldBeActive = widget.playbackController?.active ?? widget.active;
      _setLifecycleActive(shouldBeActive, reason: 'first_frame_ready');
    });
  }

  @override
  void didUpdateWidget(covariant LocalReplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.deviceAbilities != widget.deviceAbilities) {
      final isAovDevice =
          LocalReplayUiHelpers.isAovDeviceAbilities(widget.deviceAbilities);
      if (isAovDevice != _isAovDevice) {
        _bufferingState.dispose();
        _bufferingState = LocalReplayBufferingState(
          _cameraCount,
          aovCardReplay: isAovDevice,
        );
        _applyPlayerBufferingMode(_player, isAovDevice);
        if (_player1 != null) {
          _applyPlayerBufferingMode(_player1!, isAovDevice);
        }
        if (_player2 != null) {
          _applyPlayerBufferingMode(_player2!, isAovDevice);
        }
        if (_player3 != null) {
          _applyPlayerBufferingMode(_player3!, isAovDevice);
        }
      }
      _isAovDevice = isAovDevice;
    }

    if (!identical(oldWidget.playbackController, widget.playbackController)) {
      oldWidget.playbackController?._detach(this);
      widget.playbackController?._attach(this);
      _setLifecycleActive(
        widget.playbackController?.active ?? widget.active,
        reason: 'controller_changed',
      );
      return;
    }

    // The controller path is used by lifecycle-aware pages. Keep [active] for
    // tab containers that still own activity as declarative widget state.
    if (widget.playbackController == null &&
        oldWidget.active != widget.active) {
      _setLifecycleActive(widget.active, reason: 'active_property_changed');
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _recordListQuery.dispose();
    _uiReady = false;
    widget.playbackController?._detach(this);
    _bufferingState.dispose();
    _seekTimeoutTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _lifecycleActive = false;
    _stopDownload(updateState: false);
    _stopPlaybackIfNeeded('dispose');
    _dumpController.forceStopIfNeeded('dispose', notifyStateChanged: false);
    _player3?.destroy();
    _player2?.destroy();
    _player1?.destroy();
    _player.destroy();

    _stream.destroy();

    _releasePipe('dispose');
    _pipe.destroy();

    for (final controller in _frameHoldControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _log(String message) {
    Logging.i(_tag, '[device=$_deviceId] $message');
  }

  void start() =>
      _setLifecycleActive(true, reason: 'local_replay_widget_start');

  void stop() => _setLifecycleActive(false, reason: 'local_replay_widget_stop');

  void _setLifecycleActive(bool active, {required String reason}) {
    if (_isDisposing) return;
    final changed = _lifecycleActive != active;
    final cancelledRecordQuery = !active && _recordIndexQueryActive;
    _lifecycleActive = active;
    if (!active) {
      _recordListQuery.cancel();
      _recordIndexRequestGeneration += 1;
      _recordIndexQueryActive = false;
      _stopDownload();
    }
    if (changed) _lifecycleGeneration += 1;

    if (active) {
      if (!_uiReady) {
        _log('playback.start deferred reason=$reason uiReady=false');
        return;
      }
      if (changed ||
          (!_transitionActive &&
              _playbackState == _LocalReplayPlaybackState.stopped)) {
        _activateVisualTransition(
          floorUtcMs: _currentTimestampInMs,
          seeking: false,
        );
      }
      _ensureConnectionAndPlayback(reason);
      return;
    }

    if (!changed && _playbackState == _LocalReplayPlaybackState.stopped) {
      return;
    }
    if (changed) {
      // A backgrounded OHOS NativeWindow may still be present in the plugin's
      // map while no longer accepting buffers. Recreate it on the next resume.
      _forceTextureOnNextStart = true;
    }
    _activateVisualTransition(
      floorUtcMs: _currentTimestampInMs,
      seeking: false,
    );
    _bufferingState.reset(resetCadence: true);
    _seekDebounceTimer?.cancel();
    _dumpController.forceStopIfNeeded('stop', notifyStateChanged: false);
    _stopDownload();
    _stopPlaybackIfNeeded(reason);
    if (cancelledRecordQuery) _releasePipe('record_query_cancelled');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Semantics(
      key: const ValueKey('rapid-local-replay-state'),
      value: 'established=${_pipe.isEstablished} '
          'rendering=${_presentation.anyReady} '
          'ready_lanes=${_presentation.readyCount}/$_cameraCount '
          'lane_states=${_presentation.laneSummary} '
          'timestamp_ms=$_currentTimestampInMs',
      child: _root(),
    );
  }

  Widget _root() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        return Column(
          children: <Widget>[
            Expanded(
              child: _top(width),
            ),
          ],
        );
      },
    );
  }

  void _onVolumeTap() {
    setState(() {
      _audioMuted = !_audioMuted;
    });
    _applyAudioMuteState();
  }

  void _applyAudioMuteState() {
    _player.mute(_audioMuted || _primaryAudioSuppressed);
    _player1?.mute(_audioMuted);
    _player2?.mute(_audioMuted);
    _player3?.mute(_audioMuted);
  }

  void _onRecordTap() async {
    final granted =
        await RuntimePermissions.accessGranted(PermissionType.gallery);
    if (!granted) {
      final ret =
          await RuntimePermissions.requestAccess(PermissionType.gallery);
      if (ret == PermissionState.denied) return;
      return;
    }

    _videoRecording = !_videoRecording;
    if (_videoRecording) {
      final ret = await _player.startRecord();
      SnackTips.show(context, ret ? "开始录像..." : "录像失败");
    } else {
      final ret = await _player.stopRecord();
      SnackTips.show(context, ret ? "录像保存成功" : "录像保存失败");
    }
  }

  Widget _top(double width) {
    return Container(
      width: width,
      color: SampleThemeConfigure.colorVideoBackground,
      child: _buildVideoPlayerBody(width),
    );
  }

  List<Player> _dumpTargets() {
    return [
      _player,
      if (_player1 != null) _player1!,
      if (_player2 != null) _player2!,
      if (_player3 != null) _player3!,
    ];
  }

  Widget _buildDumpActionButton() {
    return _dumpController.buildActionButton(
      canStart: _pipe.isEstablished && !_establishFailed && !_loading,
      unavailableMessage: '播放尚未就绪',
    );
  }

  Widget _buildTimeline() {
    return LocalReplayTimelinePanel(
      selectedDate: _selectedDate,
      total: _recordIndexPacket?.total ?? 0,
      loading: _eventsLoading,
      error: _recordIndexError,
      records: _recordIndexPacket?.list ?? const [],
      timestampLabel: LocalReplayUiHelpers.formatTimestampLabel(
        _currentTimestampInMs,
      ),
      currentTimestampInMs: _currentTimestampInMs,
      onRetryLoad: _loadRecordIndex,
      onSeek: _seekToRecord,
      onSeekTimestamp:
          (timestampSecond, startTimestampSecond, endTimestampSecond) {
        _seekToTimestamp(
          timestampSecond,
          startTimestampSecond: _isAovDevice ? null : startTimestampSecond,
          endTimestampSecond: _isAovDevice ? null : endTimestampSecond,
        );
      },
      onUnavailableTimestamp: _onUnavailableTimestamp,
      allowUnboundedAovSeek: _isAovDevice,
      onDownloadRecord: _onDownloadRecord,
      downloading: _isDownloading,
      downloadingRecordTimestamp: _downloadingRecordTimestamp,
      downloadProgress: _totalDownloadProgress,
      onPickDate: _onPickDate,
      onDateChanged: _selectDate,
    );
  }

  Widget _buildVideoPlayerBody(double width) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final pipeState = _pipe.currentState();
        final showConnectionError =
            LocalReplayUiHelpers.shouldShowConnectionError(
          hasSelectedRecord: _hasSelectedRecord,
          establishFailed: _establishFailed,
          pipeState: pipeState,
        );

        return LocalReplayStage(
          cameraCount: _cameraCount,
          availableHeight: availableHeight,
          width: width,
          showConnectionError: showConnectionError,
          showBuffering: _loading &&
              !_paused &&
              !_presentation.anyReady &&
              (_transitionCoversTexture ||
                  _presentation.timedOut ||
                  _initialRecordMessage != null),
          bufferingMessage: _initialRecordMessage ??
              (_presentation.timedOut
                  ? '恢复超时，请切换录像或重新进入'
                  : (_presentation.seeking ? '正在切换' : '正在恢复')),
          bufferingTimedOut:
              _initialRecordMessage != null || _presentation.timedOut,
          playerStatusMessages: List.generate(
            _cameraCount,
            (index) {
              if (!_loading) return null;
              final transitionMessage = _presentation.laneMessage(index);
              if (transitionMessage != null) return transitionMessage;
              if (_bufferingState.isVisible(index) &&
                  _presentation.isReady(index)) {
                return '第${index + 1}路正在缓冲';
              }
              return null;
            },
          ),
          paused: _paused,
          // The date/index UI must remain usable before playback has a target.
          // Once a record is selected, this returns to the real pipe state.
          pipeEstablished: _pipe.isEstablished || !_hasSelectedRecord,
          connectionState: _connectionState,
          onRetryConnection: _retryConnection,
          stats: ObsWidget(deviceId: _deviceId),
          topRightOverlay: _buildDumpActionButton(),
          timelinePanel: _buildTimeline(),
          controlsPanel: LocalReplayControlsPanel(
            audioMuted: _audioMuted,
            paused: _paused,
            recording: _videoRecording,
            speedFast: _speed == LocalReplaySpeed.x4,
            onToggleMute: _onVolumeTap,
            onCapture: () => _player.capture(),
            onToggleSpeed: () {
              setState(() {
                _speed = _speed == LocalReplaySpeed.x1
                    ? LocalReplaySpeed.x4
                    : LocalReplaySpeed.x1;
              });
              _presentation.notePlaybackRate(
                _speed == LocalReplaySpeed.x4 ? 4 : 1,
              );
              SnackTips.show(context, "回放速度: ${_speed.name}");
              _stream.setSpeed(_speed);
            },
            onTogglePause: _onTogglePause,
            onToggleRecord: _onRecordTap,
          ),
          dateButton: const SizedBox.shrink(),
          texture0: _player.texture(),
          texture1: _player1?.texture(),
          texture2: _player2?.texture(),
          texture3: _player3?.texture(),
          holdController0: _frameHoldControllers[0],
          holdController1: _cameraCount > 1 ? _frameHoldControllers[1] : null,
          holdController2: _cameraCount > 2 ? _frameHoldControllers[2] : null,
          holdController3: _cameraCount > 3 ? _frameHoldControllers[3] : null,
        );
      },
    );
  }

  void _retryConnection() {
    _bufferingState.reset(resetCadence: true);
    _seekDebounceTimer?.cancel();
    _activateVisualTransition(
      floorUtcMs: _currentTimestampInMs,
      seeking: false,
    );
    setState(() {
      _loading = true;
      _establishFailed = false;
    });
    _establishRequested = false;
    _restartPlaybackWithTexture('manual_retry');
  }

  Future<void> _onDownloadRecord(RecordIndex record) async {
    if (_isDownloading) return;
    final granted = await RuntimePermissions.accessGranted(
      PermissionType.gallery,
    );
    if (!granted) {
      final permission = await RuntimePermissions.requestAccess(
        PermissionType.gallery,
      );
      if (permission != PermissionState.granted) {
        if (mounted) {
          SnackTips.show(
            context,
            "Photo permission is required to save videos",
          );
        }
        return;
      }
    }

    if (!mounted) return;
    final endTimestamp = record.endTimestampSecond;
    _log(
      '[download] start, start=${record.startTimestampSecond}, requested_end=${record.endTimestampSecond}, effective_end=$endTimestamp, cameras=$_cameraCount',
    );
    setState(() {
      _isDownloading = true;
      _downloadingRecordTimestamp = record.startTimestampSecond;
      _totalDownloadProgress = 0;
    });
    _completedDownloadCameras.clear();
    _downloadProgress.clear();
    _connectDownloadSession(record, endTimestamp);
  }

  void _connectDownloadSession(RecordIndex record, int endTimestamp) {
    try {
      final downloadPipe = Pipe.createIndependent(_deviceId);
      _downloadPipe = downloadPipe;
      downloadPipe.setTransportMode(
        SampleConstants.tgrtcTcpModeEnabled ? 1 : 0,
      );
      downloadPipe.listen((state) {
        if (!mounted || !_isActiveDownloadSession(downloadPipe)) return;
        if (state == PipeState.established) {
          _startDownloadExport(downloadPipe, record, endTimestamp);
        } else if (state != PipeState.attempting &&
            state != PipeState.undefined) {
          _failDownload(
            "Unable to connect for video download (${state.name})",
            downloadPipe: downloadPipe,
          );
        }
      });
      downloadPipe.establish();
    } catch (error) {
      _log('[download] connection setup failed, error=$error');
      _failDownload("Unable to connect for video download");
    }
  }

  Future<void> _startDownloadExport(
    Pipe downloadPipe,
    RecordIndex record,
    int endTimestamp,
  ) async {
    if (identical(_downloadStartingPipe, downloadPipe) ||
        _downloadStream != null) {
      return;
    }
    _downloadStartingPipe = downloadPipe;

    try {
      final downloadStream = LocalReplayStream.create(
        downloadPipe,
        enableAudio: _streamAudioEnabled,
      );
      if (!_isActiveDownloadSession(downloadPipe)) {
        downloadStream.destroy();
        return;
      }
      _downloadStream = downloadStream;
      downloadStream.prepare(record.startTimestampSecond, endTimestamp);
      _downloadCaptures = List<LocalReplayCapture>.generate(
        _cameraCount,
        (cameraIndex) => _createDownloadCapture(
          downloadPipe,
          downloadStream,
          cameraIndex,
        ),
      );

      final recordDateTime = DateTime.fromMillisecondsSinceEpoch(
        record.startTimestampSecond * 1000,
      );
      final dateTime =
          "${recordDateTime.year.toString().padLeft(4, '0')}-${recordDateTime.month.toString().padLeft(2, '0')}-${recordDateTime.day.toString().padLeft(2, '0')}-${recordDateTime.hour.toString().padLeft(2, '0')}-${recordDateTime.minute.toString().padLeft(2, '0')}-${recordDateTime.second.toString().padLeft(2, '0')}";
      for (var cameraIndex = 0;
          cameraIndex < _downloadCaptures.length;
          cameraIndex++) {
        if (!mounted || !_isDownloading) return;
        final started = await _downloadCaptures[cameraIndex].start(
          record.startTimestampSecond,
          endTimestamp,
          galleryName: "$dateTime-$_deviceName-camera$cameraIndex.mp4",
        );
        if (!mounted || !_isActiveDownloadSession(downloadPipe)) return;
        if (!started) {
          _failDownload(
            "Unable to create video export",
            downloadPipe: downloadPipe,
          );
          return;
        }
      }
      if (!mounted || !_isActiveDownloadSession(downloadPipe)) return;
      downloadStream.start();
      _downloadStreamStarted = true;
      downloadStream.setSpeed(LocalReplaySpeed.x4);
    } catch (error) {
      _log('[download] export setup failed, error=$error');
      _failDownload(
        "Unable to create video export",
        downloadPipe: downloadPipe,
      );
    } finally {
      if (identical(_downloadStartingPipe, downloadPipe)) {
        _downloadStartingPipe = null;
      }
    }
  }

  LocalReplayCapture _createDownloadCapture(
    Pipe downloadPipe,
    LocalReplayStream downloadStream,
    int cameraIndex,
  ) {
    final capture = LocalReplayCapture.create(
      downloadStream,
      cameraIndex: cameraIndex,
    );
    capture.onState = (state, errorCode) {
      if (!mounted || !_isActiveDownloadSession(downloadPipe)) return;
      if (state == LocalReplayCaptureState.completed) {
        _completedDownloadCameras.add(cameraIndex);
        if (_completedDownloadCameras.length == _cameraCount) {
          _completeDownload(downloadPipe);
        }
      } else if (state == LocalReplayCaptureState.error) {
        _failDownload(
          "Video export failed ($errorCode)",
          downloadPipe: downloadPipe,
        );
      }
    };
    capture.onProgress = (progress) {
      if (!mounted || !_isActiveDownloadSession(downloadPipe)) return;
      _downloadProgress[cameraIndex] = progress;
      final total = _downloadProgress.values.fold<double>(
            0,
            (sum, value) => sum + value,
          ) /
          _cameraCount;
      setState(() {
        _totalDownloadProgress = total.clamp(0.0, 1.0);
      });
    };
    return capture;
  }

  bool _isActiveDownloadSession(Pipe downloadPipe) =>
      _isDownloading && identical(_downloadPipe, downloadPipe);

  void _completeDownload(Pipe downloadPipe) {
    if (!mounted || !_isActiveDownloadSession(downloadPipe)) return;
    _log('[download] completed, cameras=$_cameraCount');
    _isDownloading = false;
    _disposeDownloadSession();
    setState(() {
      _downloadingRecordTimestamp = null;
      _totalDownloadProgress = 0;
    });
    SnackTips.show(context, "Video download completed");
  }

  void _failDownload(String message, {Pipe? downloadPipe}) {
    if (!mounted || !_isDownloading) return;
    if (downloadPipe != null && !identical(_downloadPipe, downloadPipe)) {
      return;
    }
    _log('[download] failed, message=$message');
    _stopDownload();
    SnackTips.show(context, message);
  }

  void _stopDownload({bool updateState = true}) {
    if (!_isDownloading && _downloadPipe == null && _downloadStream == null) {
      return;
    }
    _log('[download] stop');
    _isDownloading = false;
    _disposeDownloadSession();
    _downloadingRecordTimestamp = null;
    _totalDownloadProgress = 0;
    _completedDownloadCameras.clear();
    _downloadProgress.clear();
    if (updateState && mounted) setState(() {});
  }

  void _disposeDownloadSession() {
    for (final capture in _downloadCaptures) {
      capture.stop();
    }
    _downloadCaptures = <LocalReplayCapture>[];

    final downloadStream = _downloadStream;
    _downloadStream = null;
    if (downloadStream != null) {
      if (_downloadStreamStarted) downloadStream.stop();
      _downloadStreamStarted = false;
      downloadStream.destroy();
    }

    final downloadPipe = _downloadPipe;
    _downloadPipe = null;
    if (downloadPipe != null) {
      downloadPipe.listen((_) {});
      downloadPipe.abolish();
      downloadPipe.destroy();
    }
    _downloadStartingPipe = null;
  }

  void _ensureConnectionAndPlayback(String reason) {
    if (!_lifecycleActive || _isDisposing) return;
    if (!_pipeOwned) {
      _pipeOwned = true;
      _establishRequested = true;
      _log('pipe.establish reason=$reason owner=acquire');
      _pipe.establish();
      return;
    }
    if (!_hasSelectedRecord) {
      if (_pipe.isEstablished) {
        _establishRequested = false;
        _pipeSuspendedForRecordQuery = false;
      }
      if (_pipe.isEstablished &&
          _recordIndexPacket == null &&
          !_recordIndexQueryActive) {
        _loadRecordIndex();
        return;
      }
      if (!_pipe.isEstablished &&
          !_establishRequested &&
          _pipe.currentState() != PipeState.attempting) {
        _establishRequested = true;
        _log('pipe.establish reason=$reason recordQuery=true');
        _pipe.establish();
      }
      return;
    }
    if (_pipe.isEstablished) {
      _establishRequested = false;
      _startPlaybackIfNeeded(
        reason,
        forceRecreateTexture: _forceTextureOnNextStart,
      );
      return;
    }

    if (_establishRequested || _pipe.currentState() == PipeState.attempting) {
      return;
    }

    _establishRequested = true;
    _log(
      'pipe.establish reason=$reason lifecycleGeneration=$_lifecycleGeneration',
    );
    _pipe.establish();
  }

  void _startPlaybackIfNeeded(
    String reason, {
    bool forceRecreateTexture = false,
  }) {
    if (!_lifecycleActive || !_pipe.isEstablished || _isDisposing) return;
    if (_playbackState != _LocalReplayPlaybackState.stopped) {
      _log('playback.start skipped reason=$reason state=$_playbackState');
      return;
    }

    _forceTextureOnNextStart = false;
    _playbackState = _LocalReplayPlaybackState.starting;
    final commandGeneration = ++_playbackCommandGeneration;
    final lifecycleGeneration = _lifecycleGeneration;
    _log(
      'playback.start reason=$reason lifecycleGeneration=$lifecycleGeneration '
      'commandGeneration=$commandGeneration forceTexture=$forceRecreateTexture',
    );
    unawaited(
      _ensureTexturesAndStart(
        reason: reason,
        lifecycleGeneration: lifecycleGeneration,
        commandGeneration: commandGeneration,
        forceRecreateTexture: forceRecreateTexture,
      ),
    );
  }

  Future<void> _ensureTexturesAndStart({
    required String reason,
    required int lifecycleGeneration,
    required int commandGeneration,
    required bool forceRecreateTexture,
  }) async {
    try {
      await Future.wait(
        _dumpTargets().map(
          (player) => player.ensureTexture(
            forceRecreate: forceRecreateTexture,
          ),
        ),
      );
      if (!_isStartCommandCurrent(
        lifecycleGeneration: lifecycleGeneration,
        commandGeneration: commandGeneration,
      )) {
        _log(
          'playback.start cancelled reason=$reason lifecycleGeneration='
          '$lifecycleGeneration commandGeneration=$commandGeneration',
        );
        return;
      }

      _stream.start();
      if (!_isStartCommandCurrent(
        lifecycleGeneration: lifecycleGeneration,
        commandGeneration: commandGeneration,
      )) {
        _stopNativePlayback();
        return;
      }
      _player.start();
      _player1?.start();
      _player2?.start();
      _player3?.start();
      _playbackState = _LocalReplayPlaybackState.running;

      if (_paused) {
        _stream.pause();
        _player.pause();
        _player1?.pause();
        _player2?.pause();
        _player3?.pause();
      }
    } catch (error, stackTrace) {
      if (commandGeneration != _playbackCommandGeneration) return;
      _playbackState = _LocalReplayPlaybackState.stopped;
      _log('playback.start failed reason=$reason error=$error\n$stackTrace');
      if (mounted && !_isDisposing) {
        setState(() {
          _establishFailed = true;
          _connectionState = 'playback_start_failed';
        });
      }
      _stopNativePlayback();
    }
  }

  bool _isStartCommandCurrent({
    required int lifecycleGeneration,
    required int commandGeneration,
  }) {
    return mounted &&
        !_isDisposing &&
        _lifecycleActive &&
        _pipe.isEstablished &&
        lifecycleGeneration == _lifecycleGeneration &&
        commandGeneration == _playbackCommandGeneration &&
        _playbackState == _LocalReplayPlaybackState.starting;
  }

  void _stopPlaybackIfNeeded(String reason) {
    if (_playbackState == _LocalReplayPlaybackState.stopped ||
        _playbackState == _LocalReplayPlaybackState.stopping) {
      return;
    }

    _playbackState = _LocalReplayPlaybackState.stopping;
    _playbackCommandGeneration += 1;
    _log(
      'playback.stop reason=$reason lifecycleGeneration=$_lifecycleGeneration',
    );
    _stopNativePlayback();
    _playbackState = _LocalReplayPlaybackState.stopped;
  }

  void _restartPlaybackWithTexture(String reason) {
    if (!_lifecycleActive || _paused || _isDisposing) return;
    _forceTextureOnNextStart = true;
    _transitionCoversTexture = true;
    _bufferingState.reset(resetCadence: true);
    for (final controller in _frameHoldControllers) {
      controller.hold();
    }
    _stopPlaybackIfNeeded(reason);
    _ensureConnectionAndPlayback(reason);
  }

  void _stopNativePlayback() {
    try {
      _stream.stop();
    } catch (error) {
      _log('stream.stop failed: $error');
    }
    for (final player in _dumpTargets()) {
      try {
        player.stop();
      } catch (error) {
        _log('player.stop failed: $error');
      }
    }
  }

  void _prepareComponents() {
    _pipe = Pipe.create(_deviceId);
    // IMPORTANT: Only use TCP mode (1) when remote device explicitly supports it and there is a clear requirement
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _pipe.listen((state) {
      if (!mounted || _isDisposing) return;
      if (state != PipeState.established) {
        _recordQueryConnectionGeneration++;
        _recordIndexPacket = null;
        _eventsLoading = false;
      }
      if (state == PipeState.established) {
        _establishRequested = false;
        _pipeSuspendedForRecordQuery = false;
        _connectionState = null;
        setState(() {
          _establishFailed = false;
        });
        _ensureConnectionAndPlayback('pipe_established');
      } else if (state == PipeState.attempting) {
        _establishRequested = true;
        if (!_transitionActive && _currentTimestampInMs > 0) {
          _activateVisualTransition(
            floorUtcMs: _currentTimestampInMs,
            seeking: false,
          );
        }
        _stopPlaybackIfNeeded('pipe_attempting');
        setState(() => _establishFailed = false);
      } else {
        _establishRequested = false;
        if (_pipeSuspendedForRecordQuery &&
            !_hasSelectedRecord &&
            state == PipeState.abolished) {
          _connectionState = null;
          setState(() => _establishFailed = false);
          return;
        }
        if (!_transitionActive && _currentTimestampInMs > 0) {
          _activateVisualTransition(
            floorUtcMs: _currentTimestampInMs,
            seeking: false,
          );
        }
        _stopPlaybackIfNeeded('pipe_${state.name}');
        _connectionState = state.name;
        setState(() {
          _establishFailed = true;
          if (!_hasSelectedRecord && !_recordIndexQueryActive) {
            _eventsLoading = false;
            _recordIndexError = 'Device connection failed (${state.name})';
          }
        });
      }
    });

    _log('prepare_components, streamAudioEnabled=$_streamAudioEnabled');
    _stream = LocalReplayStream.create(_pipe, enableAudio: _streamAudioEnabled);
    _stream.onSeekError = _onSeekError;
    final providerPtr = _stream.provider(cameraIndex: 0)!;

    _player = _createLocalReplayPlayer();
    const audioClockTrial = RapidSampleConfigure.localReplayAudioClockTrial;
    // Keep video playback independent of audio gaps outside the explicit trial.
    _player.setClockMode(
        audioClockTrial ? PlayerClockMode.audio : PlayerClockMode.video);
    if (!audioClockTrial &&
        RapidSampleConfigure.localReplayAudioContinuityEnabled) {
      final applied = _player.setLocalReplayAudioContinuity(true);
      _log('prepare_components, audioContinuityApplied=$applied');
    }
    _configurePlayerCallbacks(_player, 0, primary: true);
    _player.prepare(providerPtr);

    if (_cameraCount > 1) {
      _player1 = _createLocalReplayPlayer();
      _configurePlayerCallbacks(_player1!, 1);
      _player1!.prepare(_stream.provider(cameraIndex: 1)!);
      _player1!.enableAudio(false);
      _player1!.bindingPrimaryPlayer(_player);
    }

    if (_cameraCount > 2) {
      _player2 = _createLocalReplayPlayer();
      _configurePlayerCallbacks(_player2!, 2);
      _player2!.prepare(_stream.provider(cameraIndex: 2)!);
      _player2!.enableAudio(false);
      _player2!.bindingPrimaryPlayer(_player);
    }

    if (_cameraCount > 3) {
      _player3 = _createLocalReplayPlayer();
      _configurePlayerCallbacks(_player3!, 3);
      _player3!.prepare(_stream.provider(cameraIndex: 3)!);
      _player3!.enableAudio(false);
      _player3!.bindingPrimaryPlayer(_player);
    }
  }

  Player _createLocalReplayPlayer() {
    final player = _createSamplePlayer();
    _applyPlayerBufferingMode(player, _isAovDevice);
    return player;
  }

  void _applyPlayerBufferingMode(Player player, bool isAovDevice) {
    if (isAovDevice) {
      player.setBufferingMode(PlayerBufferingMode.off);
      return;
    }
    player.setBufferingMode(
      PlayerBufferingMode.values[SampleConstants.bufferingMode],
      bufferingMs: SampleConstants.fixedBufferingMs,
    );
  }

  void _configurePlayerCallbacks(Player player, int index,
      {bool primary = false}) {
    player.onUniversalTimestamp = (timestamp) {
      if (!mounted ||
          _isDisposing ||
          !_lifecycleActive ||
          _paused ||
          _playbackState != _LocalReplayPlaybackState.running) {
        return;
      }
      final wasReady = _presentation.isReady(index);
      final accepted = _presentation.acceptTimestamp(
        index,
        timestamp,
        generation: _visualGeneration,
        elapsedMilliseconds: _visualTransitionClock.elapsedMilliseconds,
        playbackRate: _speed == LocalReplaySpeed.x4 ? 4 : 1,
      );
      if (!accepted) return;
      _handlePlayerPresented(index, wasReady);

      if (primary || _timestampLeaderIndex == null) {
        _timestampLeaderIndex = index;
      }
      if (_timestampLeaderIndex != index) return;

      _stream.updateLastRenderedUtc(timestamp);
      if (_currentTimestampInMs != timestamp) {
        setState(() => _currentTimestampInMs = timestamp);
      }
    };

    player.onRenderState = (state) {
      if (!mounted ||
          _isDisposing ||
          !_lifecycleActive ||
          _paused ||
          _playbackState != _LocalReplayPlaybackState.running) {
        return;
      }
      if (state == RenderState.started) {
        final wasReady = _presentation.isReady(index);
        if (_presentation.acceptStarted(index, generation: _visualGeneration)) {
          _handlePlayerPresented(index, wasReady);
        }
        return;
      }
      // Paused and completed are intentional states, not buffering failures.
      if (state != RenderState.buffering) return;
      if (_initialRecordMessage != null) return;

      _bufferingState.noteBuffering(
        index,
        () => _onBufferingVisible(index),
        scheduleVisibility: _isAovDevice || !_loading,
      );
      if (!_transitionActive) {
        if (_presentation.isReady(index)) {
          setState(() {});
        } else {
          _activateVisualTransition(
            floorUtcMs: _currentTimestampInMs,
            seeking: false,
            showLoading: false,
            affectedPlayerIndex: index,
            coverTexture: true,
          );
        }
      } else {
        final becamePending = _presentation.markBuffering(index);
        if (becamePending && _transitionCoversTexture) {
          _frameHoldControllers[index].hold();
        }
        setState(() {});
      }
    };
  }

  void _onBufferingVisible(int index) {
    if (!mounted || _isDisposing || !_lifecycleActive || _paused) return;
    if (!_bufferingState.anyVisible) return;
    if (_isAovDevice) {
      final delay = _bufferingState.visibilityDelayForLane(index);
      _log('buffering.visible policy=aov_card_replay camera=$index '
          'delayMs=${delay.inMilliseconds}');
    }
    setState(() => _loading = true);
  }

  void _handlePlayerPresented(int index, bool wasReady) {
    _initialRecordMessage = null;
    _frameHoldControllers[index].release();
    final wasBufferingVisible = _bufferingState.isVisible(index);
    _bufferingState.noteFrame(
      index,
      _frameArrivalClock.elapsedMilliseconds,
      onStalled: _isAovDevice ? () => _onBufferingVisible(index) : null,
    );
    if (wasBufferingVisible &&
        !_bufferingState.anyVisible &&
        !_transitionActive &&
        _presentation.allReady) {
      _loading = false;
    }
    if (index == 0 && _primaryAudioSuppressed) {
      _primaryAudioSuppressed = false;
      _applyAudioMuteState();
    }
    if (wasReady) {
      if (wasBufferingVisible) setState(() {});
      return;
    }
    _log('visual.presented generation=$_visualGeneration camera=$index '
        'ready=${_presentation.readySummary} '
        'lanes=${_presentation.laneSummary}');
    // Partial success makes the working cameras visible without claiming that
    // all cameras have reached the requested seek position.
    setState(() {});
    if (_firstFramePresentedGeneration != _visualGeneration) {
      _firstFramePresentedGeneration = _visualGeneration;
      widget.onFirstFramePresented?.call();
    }
    if (_presentation.allReady) _finishVisualTransition();
  }

  int _activateVisualTransition({
    required int floorUtcMs,
    required bool seeking,
    int acceptableEndUtcMs = 0,
    bool showLoading = true,
    int? affectedPlayerIndex,
    bool coverTexture = true,
    bool waitForSeek = false,
  }) {
    final generation = _presentation.begin(
      floorUtcMs: floorUtcMs,
      seeking: seeking,
      acceptableEndUtcMs: acceptableEndUtcMs,
      affectedPlayerIndex: affectedPlayerIndex,
      waitForSeek: waitForSeek,
      isAovDevice: _isAovDevice,
      playbackRate: _speed == LocalReplaySpeed.x4 ? 4 : 1,
    );
    if (affectedPlayerIndex == null) {
      _timestampLeaderIndex = null;
    }
    if (affectedPlayerIndex == null || affectedPlayerIndex == 0) {
      _primaryAudioSuppressed = true;
      _applyAudioMuteState();
    }
    _transitionCoversTexture = coverTexture;
    _visualTransitionClock.reset();
    if (!_paused) _visualTransitionClock.start();
    _bufferingState.cancelVisibilityTimers();
    _seekTimeoutTimer?.cancel();
    final affectedControllers = affectedPlayerIndex == null
        ? _frameHoldControllers
        : [_frameHoldControllers[affectedPlayerIndex]];
    for (final controller in affectedControllers) {
      if (coverTexture) {
        controller.hold();
      } else {
        controller.release();
      }
    }
    _log(
      'visual.transition generation=$generation seeking=$seeking '
      'coverTexture=$coverTexture floorUtcMs=$floorUtcMs '
      'aovSeek=${seeking && _isAovDevice} '
      'acceptableEndUtcMs=$acceptableEndUtcMs '
      'ready=${_presentation.readySummary}',
    );
    if (mounted) {
      setState(() {
        if (showLoading) _loading = true;
      });
    }
    _scheduleTransitionTimeout(generation);
    return generation;
  }

  void _scheduleTransitionTimeout(int generation) {
    _seekTimeoutTimer?.cancel();
    if (!_lifecycleActive || _paused || !_transitionActive) return;
    final timeout =
        _isAovDevice ? _aovTransitionUiTimeout : _transitionUiTimeout;
    final remaining = timeout - _visualTransitionClock.elapsed;
    _seekTimeoutTimer =
        Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (!mounted ||
          _isDisposing ||
          !_lifecycleActive ||
          !_presentation.expire(generation)) {
        return;
      }
      _log('visual.timeout generation=$generation '
          'ready=${_presentation.readySummary} '
          'lanes=${_presentation.laneSummary}');
      // A failed lane must not restart cameras that are already playing.
      // Seeking another record or re-entering the page remains user controlled.
      setState(() => _loading = true);
    });
  }

  void _finishVisualTransition() {
    if (!_presentation.allReady) return;
    _visualTransitionClock.stop();
    _seekTimeoutTimer?.cancel();
    for (final controller in _frameHoldControllers) {
      controller.release();
    }
    if (mounted) {
      setState(() => _loading = false);
      widget.onPlaybackReady?.call();
    }
  }

  void _onSeekError(LocalReplaySeekFailure failure) {
    final generation = _visualGeneration;
    final targetUtcMs = failure.targetTimestampSecond * 1000;
    if (!mounted ||
        _isDisposing ||
        !_lifecycleActive ||
        _paused ||
        !_presentation.expireSeekFailure(generation, targetUtcMs)) {
      _log(
        'playback.seek_error_ignored error=${failure.error.name} '
        'target=${failure.targetTimestampSecond} '
        'actual=${failure.actualTimestampSecond}',
      );
      return;
    }
    _visualTransitionClock.stop();
    _seekTimeoutTimer?.cancel();
    _bufferingState.cancelVisibilityTimers();
    const message = '录像定位失败，请重试';
    _log(
      'playback.seek_error error=${failure.error.name} '
      'target=${failure.targetTimestampSecond} '
      'actual=${failure.actualTimestampSecond}',
    );
    setState(() {
      _initialRecordMessage = message;
      _loading = true;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    SnackTips.show(context, message);
  }

  void _seekToRecord(RecordIndex record, {bool immediate = false}) {
    _seekToTimestamp(
      record.startTimestampSecond,
      immediate: immediate,
      startMode: LocalReplayStartMode.singleRecord,
      startTimestampSecond: record.startTimestampSecond,
      endTimestampSecond: record.endTimestampSecond,
    );
  }

  void _onUnavailableTimestamp(int timestampSecond) {
    _log('playback.seek_unavailable target=$timestampSecond');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    SnackTips.show(context, '该时间段没有录像');
  }

  void _seekToTimestamp(
    int timestampSecond, {
    bool immediate = false,
    LocalReplayStartMode startMode = LocalReplayStartMode.continuous,
    int? startTimestampSecond,
    int? endTimestampSecond,
  }) {
    final int generation = ++_seekUiGeneration;
    _selectFirstRecordAfterLoad = false;
    _initialRecordMessage = null;
    _bufferingState.reset(resetCadence: true);
    _seekDebounceTimer?.cancel();

    final aovTimelineSeek =
        _isAovDevice && startMode == LocalReplayStartMode.continuous;
    final visualEndTimestampSecond = endTimestampSecond ??
        (_isAovDevice
            ? LocalReplayUiHelpers.dayStartSecond(DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day + 1,
              ))
            : 0);
    final visualGeneration = _activateVisualTransition(
      floorUtcMs: timestampSecond * 1000,
      seeking: true,
      acceptableEndUtcMs: visualEndTimestampSecond * 1000,
      coverTexture: !aovTimelineSeek,
      waitForSeek: true,
    );

    if (immediate) {
      unawaited(_performSeek(
        timestampSecond,
        generation,
        visualGeneration,
        startMode,
        startTimestampSecond,
        endTimestampSecond,
      ));
    } else {
      _seekDebounceTimer = Timer(_seekDebounceDelay, () {
        unawaited(_performSeek(
          timestampSecond,
          generation,
          visualGeneration,
          startMode,
          startTimestampSecond,
          endTimestampSecond,
        ));
      });
    }
  }

  Future<void> _performSeek(
    int timestampSecond,
    int generation,
    int visualGeneration,
    LocalReplayStartMode startMode,
    int? startTimestampSecond,
    int? endTimestampSecond,
  ) async {
    if (!mounted ||
        _isDisposing ||
        !_lifecycleActive ||
        generation != _seekUiGeneration ||
        visualGeneration != _visualGeneration) {
      return;
    }
    if (_videoRecording) {
      await _player.stopRecord();
      if (!mounted ||
          _isDisposing ||
          !_lifecycleActive ||
          generation != _seekUiGeneration ||
          visualGeneration != _visualGeneration) {
        return;
      }
      _videoRecording = false;
    }

    if (!_presentation.armSeek(visualGeneration)) return;
    _stream.seek(
      timestampSecond,
      startMode: startMode,
    );
    _hasSelectedRecord = true;
    _pipeSuspendedForRecordQuery = false;
    if (_playbackState == _LocalReplayPlaybackState.stopped) {
      _ensureConnectionAndPlayback('seek_target_selected');
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    SnackTips.show(context, "切换${timestampSecond.toHHmmss()}中");
  }

  void _loadRecordIndex() async {
    if (!mounted ||
        _isDisposing ||
        !_lifecycleActive ||
        _recordIndexQueryActive) {
      return;
    }
    if (!_pipe.isEstablished) {
      _ensureConnectionAndPlayback('record_index_requires_connection');
      return;
    }
    _recordIndexQueryActive = true;
    final requestGeneration = ++_recordIndexRequestGeneration;
    final commandGeneration = _playbackCommandGeneration;
    final connectionGeneration = _recordQueryConnectionGeneration;
    var succeeded = false;
    final seekGeneration = _seekUiGeneration;
    final selectedDate = _selectedDate;
    final date = _selectedDate.toStandardDate();
    setState(() {
      _eventsLoading = true;
      _recordIndexPacket = null;
      _recordIndexError = null;
      _initialRecordMessage = null;
    });

    bool isCurrent() =>
        mounted &&
        !_isDisposing &&
        _lifecycleActive &&
        requestGeneration == _recordIndexRequestGeneration &&
        connectionGeneration == _recordQueryConnectionGeneration &&
        _pipe.isEstablished &&
        commandGeneration == _playbackCommandGeneration &&
        date == _selectedDate.toStandardDate();

    bool canSelectInitial() {
      if (_paused ||
          seekGeneration != _seekUiGeneration ||
          _seekDebounceTimer?.isActive == true ||
          _playbackState == _LocalReplayPlaybackState.starting ||
          _playbackState == _LocalReplayPlaybackState.stopping) {
        return false;
      }
      if (_selectFirstRecordAfterLoad) return true;
      return !_hasSelectedRecord &&
          !_presentation.anyReady &&
          _currentTimestampInMs <= 0;
    }

    try {
      _log('record_index.begin generation=$requestGeneration date=$date');
      final response = await _recordListQuery.load(date);
      succeeded = response.success;
      final cleanup = await _recordListQuery.wait_for_cleanup();
      if (!isCurrent()) {
        _log('record_index.drop generation=$requestGeneration date=$date');
        return;
      }
      if (!cleanup.success) {
        throw StateError(cleanup.message ?? 'Record query cleanup failed');
      }
      _log('record_index.complete generation=$requestGeneration date=$date '
          'code=${response.code} count=${response.data?.list.length}');
      if (response.success) {
        _recordIndexPacket = response.data;
        final records = response.data?.list ?? const <RecordIndex>[];
        final first =
            LocalReplayUiHelpers.firstPlayableRecord(records, selectedDate);
        final hasUnboundedAovDay = _isAovDevice &&
            response.data != null &&
            (response.data!.total > 0 || records.isNotEmpty) &&
            first == null;
        if (canSelectInitial()) {
          _selectFirstRecordAfterLoad = false;
          if (first != null) {
            _log('playback.initial_record date=$date '
                'target=${first.startTimestampSecond}');
            _seekToRecord(first, immediate: true);
          } else if (hasUnboundedAovDay) {
            final dayStart = LocalReplayUiHelpers.dayStartSecond(selectedDate);
            _log('playback.initial_aov_day date=$date target=$dayStart');
            _seekToTimestamp(dayStart, immediate: true);
          } else {
            _initialRecordMessage = '当天没有可播放录像，请切换日期';
          }
        }
        if ((response.data?.list.isEmpty ?? true) && !hasUnboundedAovDay) {
          SnackTips.show(context, '当天没有录像记录');
        }
      } else {
        _recordIndexError = response.message?.trim().isNotEmpty == true
            ? response.message
            : 'Record list query failed (code=${response.code})';
        if (canSelectInitial()) _initialRecordMessage = '录像列表获取失败，请重试';
        SnackTips.show(context, _recordIndexError!);
        _resetPipeAfterRecordQueryFailure();
      }
    } catch (error) {
      if (!isCurrent()) return;
      _log('record_index failed date=$date error=$error');
      _recordIndexError = 'Record list query failed: $error';
      if (canSelectInitial()) _initialRecordMessage = '录像列表获取失败，请重试';
      _resetPipeAfterRecordQueryFailure();
    } finally {
      if (requestGeneration == _recordIndexRequestGeneration) {
        _recordIndexQueryActive = false;
        if (mounted && !_isDisposing) {
          final connectionChanged =
              connectionGeneration != _recordQueryConnectionGeneration;
          final dateChanged = date != _selectedDate.toStandardDate();
          if (_lifecycleActive &&
              _pipe.isEstablished &&
              (connectionChanged || (succeeded && dateChanged))) {
            _loadRecordIndex();
          } else {
            setState(() => _eventsLoading = false);
          }
        }
      }
    }
  }

  void _onTogglePause() {
    _paused = !_paused;
    _presentation.paused = _paused;
    if (_paused) {
      _visualTransitionClock.stop();
      _seekTimeoutTimer?.cancel();
      _bufferingState.reset(resetCadence: true);
      _stream.pause();

      _player.pause();
      _player1?.pause();
      _player2?.pause();
      _player3?.pause();

      SnackTips.show(context, "已暂停播放");
    } else {
      if (_transitionActive) {
        _visualTransitionClock.start();
        _scheduleTransitionTimeout(_visualGeneration);
        _loading = true;
      }
      _stream.resume();

      _player.resume();
      _player1?.resume();
      _player2?.resume();
      _player3?.resume();

      if (!_hasSelectedRecord && _currentTimestampInMs <= 0) _loadRecordIndex();

      SnackTips.show(context, "已恢复播放");
    }

    setState(() => _paused = _paused);
  }

  void _onPickDate() async {
    DateTime? pickedDate =
        await LocalReplayDatePicker.pick(context, _selectedDate);

    if (pickedDate != null) _selectDate(pickedDate);
  }

  void _selectDate(DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final latest = DateTime(today.year, today.month, today.day);
    if (selected.isAfter(latest) ||
        LocalReplayUiHelpers.isSameDate(selected, _selectedDate)) {
      return;
    }
    _recordIndexRequestGeneration += 1;
    _recordIndexQueryActive = false;
    _pipeSuspendedForRecordQuery = true;
    _stopPlaybackIfNeeded('date_changed');
    final pipeState = _pipe.currentState();
    if (pipeState == PipeState.established ||
        pipeState == PipeState.attempting) {
      _releasePipe('date_changed');
    }
    _recordListQuery.cancel();
    _activateVisualTransition(
      floorUtcMs: 0,
      seeking: false,
      coverTexture: true,
    );
    setState(() {
      _selectedDate = selected;
      _recordIndexPacket = null;
      _eventsLoading = true;
      _recordIndexError = null;
      _hasSelectedRecord = false;
      _selectFirstRecordAfterLoad = true;
      _currentTimestampInMs = 0;
    });
    unawaited(_reloadRecordIndexAfterCleanup(selected));
  }

  Future<void> _reloadRecordIndexAfterCleanup(DateTime selectedDate) async {
    await _recordListQuery.wait_for_cleanup();
    if (!mounted ||
        _isDisposing ||
        !_lifecycleActive ||
        !LocalReplayUiHelpers.isSameDate(selectedDate, _selectedDate)) {
      return;
    }
    _ensureConnectionAndPlayback('record_index_date_changed');
  }

  void _resetPipeAfterRecordQueryFailure() {
    final pipeState = _pipe.currentState();
    if (pipeState != PipeState.established &&
        pipeState != PipeState.attempting) {
      return;
    }
    _pipeSuspendedForRecordQuery = true;
    _releasePipe('record_query_failed');
  }

  void _releasePipe(String reason) {
    _log('pipe.abolish reason=$reason owned=$_pipeOwned '
        'state=${_pipe.currentState()}');
    _pipeOwned = false;
    _establishRequested = false;
    _pipe.abolish();
  }
}
