part of '../rapid_kit_sample_pages.dart';

class LocalReplayWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final String? deviceAbilities;
  final bool active;

  const LocalReplayWidget({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    this.deviceAbilities,
    this.active = false,
  });

  @override
  State<LocalReplayWidget> createState() => _LocalReplayWidgetState();
}

class _LocalReplayWidgetState extends State<LocalReplayWidget>
    with AutomaticKeepAliveClientMixin {
  static const String _tag = "_LocalReplayWidget_";

  // The native layer reports buffering if no video dequeued for 1s.
  // To avoid UI flicker (or false-positive buffering on low-fps AOV replay),
  // debounce the buffering indicator.
  static const Duration _bufferingUiDelay = Duration(seconds: 10);

  late String _deviceId;
  late String _deviceName;
  late int _cameraCount;
  late bool _streamAudioEnabled;

  bool _audioMuted = false;
  bool _videoRecording = false;
  bool _eventsLoading = true;
  bool _recordQueryInFlight = false;
  // ignore: non_constant_identifier_names
  int _record_query_connection_generation = 0;
  bool _establishFailed = false;
  String? _connectionState;

  late Pipe _pipe;
  late LocalReplayStream _stream;
  Pipe? _downloadPipe;
  LocalReplayStream? _downloadStream;
  late Player _player;
  Player? _player1;
  Player? _player2;
  List<LocalReplayCapture> _downloadCaptures = <LocalReplayCapture>[];
  final Set<int> _completedDownloadCameras = <int>{};
  final Map<int, double> _downloadProgress = <int, double>{};
  bool _isDownloading = false;
  Pipe? _downloadStartingPipe;
  bool _downloadStreamStarted = false;
  int? _downloadingRecordTimestamp;
  double _totalDownloadProgress = 0;

  int _currentTimestampInMs = 0;

  LocalReplaySpeed _speed = LocalReplaySpeed.x1;

  RecordIndexPacket? _recordIndexPacket;
  // ignore: non_constant_identifier_names
  int _record_request_generation = 0;

  DateTime _selectedDate = DateTime.now();
  final DateTime _todayDate = DateTime.now();

  bool _paused = false;

  bool _loading = true;

  Timer? _bufferingDelayTimer;
  bool _isBuffering = false;
  late final MediaDumpController _dumpController;

  @override
  void initState() {
    super.initState();

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;
    _cameraCount = widget.cameraCount;
    _streamAudioEnabled =
        DeviceAudioCapability.streamAudioEnabledFromDeviceAbilities(
      widget.deviceAbilities,
    );
    _prepareComponents();
    _dumpController = MediaDumpController(
      context: () => context,
      mounted: () => mounted,
      players: _dumpTargets,
      chatSessions: () => const <MediaDumpSender>[],
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
  void didUpdateWidget(covariant LocalReplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.active == widget.active) {
      return;
    }

    if (widget.active) {
      start();
    } else {
      stop();
    }
  }

  @override
  void dispose() {
    _bufferingDelayTimer?.cancel();
    _isBuffering = false;
    _dumpController.forceStopIfNeeded('dispose', notifyStateChanged: false);
    _stopDownload(updateState: false);
    _player2?.destroy();
    _player1?.destroy();
    _player.destroy();

    _stream.destroy();

    _pipe.abolish();
    _pipe.destroy();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _log(String message) {
    Logging.i(_tag, '[device=$_deviceId] $message');
  }

  void start() {
    // 恢复时尝试重新建立连接（P2P 可能会由于处于后台等原因被系统断开）
    if (!_pipe.isEstablished) {
      _pipe.establish();
    }

    if (_pipe.isEstablished) {
      _launchPlayback();
    }
  }

  void stop() {
    _bufferingDelayTimer?.cancel();
    _isBuffering = false;
    _dumpController.forceStopIfNeeded('stop', notifyStateChanged: false);
    _stopDownload();
    _stream.stop();
    _player.stop();
    _player1?.stop();
    _player2?.stop();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _root();
  }

  Widget _root() {
    return Semantics(
      key: const ValueKey('rapid-local-replay-state'),
      value: 'established=${_pipe.isEstablished};'
          'rendering=${!_loading && !_establishFailed};'
          'buffering=$_loading;paused=$_paused;'
          'timestamp_ms=$_currentTimestampInMs',
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          return Column(children: <Widget>[Expanded(child: _top(width))]);
        },
      ),
    );
  }

  void _onVolumeTap() {
    if (_player.isMute()) {
      _player.mute(false);
    } else {
      _player.mute(true);
    }

    _player1?.mute(_player.isMute());
    _player2?.mute(_player.isMute());

    setState(() {
      _audioMuted = _player.isMute();
    });
  }

  void _onRecordTap() async {
    final granted = await RuntimePermissions.accessGranted(
      PermissionType.gallery,
    );
    if (!granted) {
      final ret = await RuntimePermissions.requestAccess(
        PermissionType.gallery,
      );
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
    ];
  }

  Widget _buildDumpActionButton() {
    return _dumpController.buildActionButton(
      canStart: _pipe.isEstablished && !_establishFailed && !_loading,
      unavailableMessage: '播放尚未就绪',
    );
  }

  Widget _buildFloatingTimeline(double parentHeight) {
    final panel = LocalReplayTimelinePanel(
      selectedDate: _selectedDate,
      total: _recordIndexPacket?.list.length ?? 0,
      loading: _eventsLoading,
      downloading: _isDownloading,
      downloadingRecordTimestamp: _downloadingRecordTimestamp,
      downloadProgress: _totalDownloadProgress,
      records: _recordIndexPacket?.list ?? const [],
      timestampLabel: LocalReplayUiHelpers.formatTimestampLabel(
        _currentTimestampInMs,
      ),
      onRetryLoad: _loadRecordIndex,
      onSeek: (record) {
        _stream.seek(record.startTimestampSecond);
        SnackTips.show(context, "切换${record.startTimestampSecond.toHHmmss()}中");
      },
      onDownload: _onDownloadRecord,
    );

    return LocalReplayTimelineOverlay(
      width: LocalReplayUiConstants.timelineWidth,
      child: panel,
    );
  }

  Widget _buildVideoPlayerBody(double width) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final pipeState = _pipe.currentState();
        final showConnectionError = _establishFailed ||
            (pipeState != PipeState.attempting &&
                pipeState != PipeState.established);

        return LocalReplayStage(
          cameraCount: _cameraCount,
          availableHeight: availableHeight,
          width: width,
          showConnectionError: showConnectionError,
          showBuffering: _loading && !_paused,
          paused: _paused,
          pipeEstablished: _pipe.isEstablished,
          connectionState: _connectionState,
          onRetryConnection: _retryConnection,
          stats: ObsWidget(deviceId: _deviceId),
          topRightOverlay: _buildDumpActionButton(),
          timelinePanel: _buildFloatingTimeline(availableHeight),
          controlsPanel: LocalReplayControlsPanel(
            audioMuted: _audioMuted,
            paused: _paused,
            recording: _videoRecording,
            speedFast: _speed == LocalReplaySpeed.x4,
            onToggleMute: _onVolumeTap,
            onCapture: () => _player.capture(),
            onToggleSpeed: () {
              _speed = _speed == LocalReplaySpeed.x1
                  ? LocalReplaySpeed.x4
                  : LocalReplaySpeed.x1;
              SnackTips.show(context, "回放速度: ${_speed.name}");
              _stream.setSpeed(_speed);
            },
            onTogglePause: _onTogglePause,
            onToggleRecord: _onRecordTap,
          ),
          dateButton: _buildFloatingDateButton(),
          texture0: _player.texture(),
          texture1: _player1?.texture(),
          texture2: _player2?.texture(),
        );
      },
    );
  }

  void _retryConnection() {
    _bufferingDelayTimer?.cancel();
    _isBuffering = false;
    setState(() {
      _loading = true;
      _establishFailed = false;
    });
    start();
  }

  void _launchPlayback() {
    _stream.start();
    _player.start();
    _player1?.start();
    _player2?.start();
    _loadRecordIndex();
  }

  void _prepareComponents() {
    _pipe = Pipe.create(_deviceId);
    // IMPORTANT: Only use TCP mode (1) when remote device explicitly supports it and there is a clear requirement
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _pipe.listen((state) {
      if (!mounted) return;
      if (state != PipeState.established) {
        _record_query_connection_generation++;
        _recordIndexPacket = null;
        _eventsLoading = false;
      }
      if (state == PipeState.established) {
        setState(() {
          _establishFailed = false;
        });
        if (widget.active) {
          _launchPlayback();
        }
      } else if (state == PipeState.attempting) {
        setState(() => _establishFailed = false);
      } else {
        _connectionState = state.name;
        setState(() => _establishFailed = true);
      }
    });

    _log('prepare_components, streamAudioEnabled=$_streamAudioEnabled');
    _stream = LocalReplayStream.create(_pipe, enableAudio: _streamAudioEnabled);
    final providerPtr = _stream.provider(cameraIndex: 0)!;

    _player = _createSamplePlayer();
    _player.onUniversalTimestamp = (timestamp) {
      // use timestamp to sync your ui, e.g. seek bar / timeline
      setState(() {
        _currentTimestampInMs = timestamp;
      });
    };
    _player.prepare(providerPtr);
    _player.onRenderState = (state) {
      if (!mounted) return;

      if (state == RenderState.started) {
        _isBuffering = false;
        _bufferingDelayTimer?.cancel();
        if (_loading) {
          setState(() => _loading = false);
        }
        return;
      }

      // Buffering (or other non-started states): delay showing loading.
      _isBuffering = true;
      if (_loading) return;

      _bufferingDelayTimer?.cancel();
      _bufferingDelayTimer = Timer(_bufferingUiDelay, () {
        if (!mounted) return;
        if (_isBuffering && !_paused) {
          setState(() => _loading = true);
        }
      });
    };

    if (_cameraCount > 1) {
      _player1 = _createSamplePlayer();
      _player1!.prepare(_stream.provider(cameraIndex: 1)!);
      _player1!.enableAudio(false);
      _player1!.bindingPrimaryPlayer(_player);
    }

    if (_cameraCount > 2) {
      _player2 = _createSamplePlayer();
      _player2!.prepare(_stream.provider(cameraIndex: 2)!);
      _player2!.enableAudio(false);
      _player2!.bindingPrimaryPlayer(_player);
    }
  }
  void _loadRecordIndex() async {
    if (!mounted || _recordQueryInFlight) return;
    _recordQueryInFlight = true;
    final generation = ++_record_request_generation;
    final connectionGeneration = _record_query_connection_generation;
    final date = _selectedDate.toStandardDate();
    var succeeded = false;
    setState(() {
      _eventsLoading = true;
      _recordIndexPacket = null;
    });
    try {
      final response = await InstructStandard.listRecords(_pipe, date);
      succeeded = response.success;
      if (!mounted || generation != _record_request_generation ||
          connectionGeneration != _record_query_connection_generation ||
          !_pipe.isEstablished ||
          date != _selectedDate.toStandardDate()) {
        return;
      }
      if (response.success) {
        _recordIndexPacket = response.data;
        if (response.data?.list.isEmpty ?? true) {
          SnackTips.show(context, 'No recordings for this date');
        }
      } else {
        SnackTips.show(context, response.message ?? 'Record query failed: ${response.code}');
      }
    } finally {
      _recordQueryInFlight = false;
      if (mounted) {
        if (connectionGeneration != _record_query_connection_generation) {
          if (_pipe.isEstablished && widget.active) {
            _loadRecordIndex();
          } else {
            setState(() => _eventsLoading = false);
          }
        } else if (succeeded && date != _selectedDate.toStandardDate()) {
          _loadRecordIndex();
        } else {
          if (!succeeded && date != _selectedDate.toStandardDate()) {
            SnackTips.show(context, 'Record query failed; retry after recovery');
          }
          setState(() => _eventsLoading = false);
        }
      }
    }
  }

  void _onTogglePause() {
    _paused = !_paused;
    if (_paused) {
      _stream.pause();

      _player.pause();
      _player1?.pause();
      _player2?.pause();

      SnackTips.show(context, "已暂停播放");
    } else {
      _stream.resume();

      _player.resume();
      _player1?.resume();
      _player2?.resume();

      SnackTips.show(context, "已恢复播放");
    }

    setState(() => _paused = _paused);
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

  Widget _buildFloatingDateButton() {
    return LocalReplayDateButton(onTap: _onPickDate);
  }

  void _onPickDate() async {
    DateTime? pickedDate = await LocalReplayDatePicker.pick(
      context,
      _selectedDate,
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _eventsLoading = true;
      });
      _loadRecordIndex();
    }
  }
}
