part of '../rapid_kit_sample_pages.dart';

class CloudReplayDownloadButton extends StatelessWidget {
  final bool downloadInProgress;
  final bool currentDownload;
  final bool cancelEnabled;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const CloudReplayDownloadButton({
    super.key,
    required this.downloadInProgress,
    required this.currentDownload,
    required this.cancelEnabled,
    required this.progress,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final percent = (normalizedProgress * 100).round();
    final onPressed = currentDownload
        ? (cancelEnabled ? onCancel : null)
        : (downloadInProgress ? null : onDownload);

    return Tooltip(
      message: currentDownload
          ? cancelEnabled
              ? "Downloading $percent%, tap to cancel"
              : "Downloading $percent%"
          : "下载",
      child: SizedBox(
        width: 60,
        height: 32,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: SampleThemeConfigure.colorPrimary.withOpacity(
              0.75,
            ),
            side: BorderSide(
              color: SampleThemeConfigure.colorPrimary.withOpacity(0.3),
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.zero,
          ),
          child: currentDownload
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        value: normalizedProgress,
                        strokeWidth: 2,
                        backgroundColor:
                            SampleThemeConfigure.colorPrimary.withOpacity(0.15),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text("$percent%", style: const TextStyle(fontSize: 11)),
                  ],
                )
              : const Text("下载", style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class CloudReplayPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final Timezone? deviceTimezone;

  const CloudReplayPage(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.cameraCount,
      this.deviceTimezone});

  @override
  State<CloudReplayPage> createState() => _CloudReplayPageState();
}

class _CloudReplayPageState extends LifecycleAwareState<CloudReplayPage>
    with WidgetsBindingObserver {
  static const String _tag = "_CloudReplayPage_";
  static const int _completionTimestampToleranceMs = 2000;
  static const TextStyle _timestampLabelStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  double _measureTimestampLabelWidth(BuildContext context) {
    final painter = TextPainter(
      text: const TextSpan(text: '00:00:00', style: _timestampLabelStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble() + 2;
    painter.dispose();
    return width;
  }

  late String _deviceId;
  late String _deviceName;
  bool _audioMuted = false;
  bool _eventsLoading = true;

  late int _cameraCount;

  late CloudReplayStream _stream;
  late Player _player;

  Player? _player1;
  Player? _player2;
  Player? _player3;

  late CloudReplayStream _streamOfDownload;
  late List<CloudReplayCapture> _downloadCaptures;
  final Set<int> _completedDownloadCameras = <int>{};
  final Map<int, double> _downloadProgress = <int, double>{};
  bool _isDownloading = false;
  bool _downloadCanCancel = false;
  double _totalDownloadProgress = 0;
  String? _downloadingRecordKey;

  int _currentPartStartTimestampInMs = 0;
  int _currentPartEndTimestampInMs = 0;
  int _currentTimestampInMs = 0;
  final CloudReplayTimelineState _playbackTimeline = CloudReplayTimelineState();
  int? _pendingPtsInMs;
  int? _lastAcceptedPtsInMs;
  int? _lastAcceptedUtsInMs;
  bool _recordClicked = false;
  bool _seekDragging = false;
  int _seekPosition = 0;

  CloudRecordIndexPacket? _recordIndexPacket;

  CloudReplaySpeed _speed = CloudReplaySpeed.x1;

  late DateTime _selectedDate;
  late CloudReplayTimeZone _deviceTimeZone;
  String? _deviceTimeRaw;
  int _dateSelectionGeneration = 0;
  int _recordIndexRequestGeneration = 0;

  RenderState _currentRenderState = RenderState.buffering;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("云录像",
            style: TextStyle(
                color: SampleThemeConfigure.colorPrimary, fontSize: 18)),
        backgroundColor: SampleThemeConfigure.colorBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: SampleThemeConfigure.colorPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          _datePicker(),
        ],
      ),
      body: _root(),
    );
  }

  Widget _root() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = width * 9 / 16;

        return Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _top(width, height),
                _seekbarWithTimestamps(),
                _statsContainer(),
                _middle(),
                Expanded(
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: _bottom(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _seekbarWithTimestamps() {
    if (_currentTimestampInMs == 0) {
      return const SizedBox();
    }

    int current = _currentTimestampInMs - _currentPartStartTimestampInMs;
    int total = _currentPartEndTimestampInMs - _currentPartStartTimestampInMs;

    if (_seekDragging) {
      current = _seekPosition;
    }

    if (current < 0) {
      current = 0;
    }

    if (total < 0) {
      total = 0;
    }

    if (current > total) {
      current = total;
    }

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final timestampLabelWidth = _measureTimestampLabelWidth(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: SampleThemeConfigure.colorVideoBackground,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                SizedBox(
                  width: timestampLabelWidth,
                  child: Text(
                    _deviceTimeZone.formatTimestamp(_currentTimestampInMs),
                    style: _timestampLabelStyle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      trackShape: const _CloudReplaySliderTrackShape(),
                      activeTrackColor: const Color(0xFF2196F3),
                      inactiveTrackColor: const Color(0xFF181818),
                      thumbColor: Colors.white,
                      thumbShape: const _CloudReplaySliderThumbShape(),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _seekDragging
                          ? _seekPosition.toDouble()
                          : current.toDouble(),
                      min: 0,
                      max: total.toDouble(),
                      onChangeStart: (value) {
                        _seekDragging = true;
                        _seekPosition = value.toInt();
                      },
                      onChangeEnd: (value) {
                        _onSeekEnd();
                      },
                      onChanged: (value) {
                        if (_seekDragging) _seekPosition = value.toInt();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: timestampLabelWidth,
                  child: Text(
                    _deviceTimeZone
                        .formatTimestamp(_currentPartEndTimestampInMs),
                    style: _timestampLabelStyle,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statsContainer() {
    if (_currentTimestampInMs == 0) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: SampleThemeConfigure.colorVideoBackground,
      child: ObsWidget(deviceId: _deviceId),
    );
  }

  void _onSeekEnd() {
    if (_seekDragging) {
      final seekTimestamp =
          ((_currentPartStartTimestampInMs + _seekPosition) / 1000).ceil();

      // Stop the old playback before installing callbacks for the new seek.
      // Otherwise a late frame emitted by stop() can become the new baseline.
      _player.stop();
      _player1?.stop();
      _player2?.stop();
      _player3?.stop();

      final generation = _playbackTimeline.begin(
        startTimestampInMs: _currentPartStartTimestampInMs,
        endTimestampInMs: _currentPartEndTimestampInMs,
        minimumTimestampInMs: seekTimestamp * 1000,
      );
      _bindPlaybackTimeline(generation);
      setState(() {
        _currentTimestampInMs = seekTimestamp * 1000;
        _currentRenderState = RenderState.buffering;
        _seekDragging = false;
      });
      Logging.i(
          _tag,
          '[playback_seek] generation=$generation, '
          'target_uts_ms=${seekTimestamp * 1000}');

      _stream.seek(seekTimestamp);
      _player.start();
      _player1?.start();
      _player2?.start();
      _player3?.start();
      return;
    }
    _seekDragging = false;
  }

  String _formatTime(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Widget _middle() {
    return Container(
      height: 70,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _pauseControl(),
          _muteControl(),
          _screenshot(),
          _speedControl(),
        ],
      ),
    );
  }

  Widget _speedControl() {
    final speedLabel = '${_speed.name.substring(1)}×';
    final speedActive = _speed != CloudReplaySpeed.x1;

    return Tooltip(
      message: '当前播放速度：$speedLabel',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(72, 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: speedActive
              ? SampleThemeConfigure.colorPrimary
              : SampleThemeConfigure.colorTextPrimary,
          backgroundColor: speedActive
              ? SampleThemeConfigure.colorPrimary.withOpacity(0.12)
              : Colors.transparent,
          side: BorderSide(
            color: speedActive
                ? SampleThemeConfigure.colorPrimary
                : SampleThemeConfigure.colorTextPrimary.withOpacity(0.35),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.speed_rounded, size: 21),
        label: Text(
          speedLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          setState(() {
            _speed = _speed == CloudReplaySpeed.x1
                ? CloudReplaySpeed.x4
                : CloudReplaySpeed.x1;
          });
          _stream.setSpeed(_speed);

          SnackTips.show(context, "速度切换为${_speed.name}");
        },
      ),
    );
  }

  IconButton _pauseControl() {
    return IconButton(
      icon: Icon(
          _currentRenderState == RenderState.paused
              ? Icons.play_circle_filled_rounded
              : Icons.pause_circle_filled_outlined,
          size: 25,
          color: SampleThemeConfigure.colorTextPrimary),
      onPressed: () {
        if (_currentRenderState == RenderState.paused) {
          _stream.resume();
          _player.resume();

          _player1?.resume();
          _player2?.resume();
          _player3?.resume();

          SnackTips.show(context, "已恢复播放");
        } else {
          _stream.pause();
          _player.pause();

          _player1?.pause();
          _player2?.pause();
          _player3?.pause();

          SnackTips.show(context, "已暂停播放");
        }
        // player will notify render state change later
      },
    );
  }

  IconButton _screenshot() {
    return IconButton(
      icon: const Icon(Icons.camera_alt,
          size: 25, color: SampleThemeConfigure.colorTextPrimary),
      onPressed: () {},
    );
  }

  IconButton _muteControl() {
    return IconButton(
      icon: Icon(
          _audioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 25,
          color: SampleThemeConfigure.colorTextPrimary),
      onPressed: () => _onVolumeTap(),
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
    _player3?.mute(_player.isMute());

    setState(() {
      _audioMuted = _player.isMute();
    });
  }

  Widget _top(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: SampleThemeConfigure.colorVideoBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildVideoPlayerBody(width),
          if (!_recordClicked)
            Text(
              "点击下方列表选择录像片段",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // 可根据需要调整字体大小
              ),
            ),
          if (_currentRenderState == RenderState.paused)
            Text(
              "已被暂停",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // 可根据需要调整字体大小
              ),
            ),
          if (_currentRenderState == RenderState.completed)
            Text(
              "这段录像播完了",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // 可根据需要调整字体大小
              ),
            ),
          if (_seekDragging) //
            Text(
              "松手以播放 ${_deviceTimeZone.formatTimestamp(_currentPartStartTimestampInMs + _seekPosition)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // 可根据需要调整字体大小
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottom() {
    return Column(
      children: <Widget>[
        Expanded(
          child: _listContainer(),
        ),
      ],
    );
  }

  Container _categoriesBar() {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _datePicker(),
        ],
      ),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async => _onPickDate(),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.calendar_month,
              size: 16,
              color: SampleThemeConfigure.colorPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              _formattedDateString(),
              style: const TextStyle(
                  fontSize: 14.0, color: SampleThemeConfigure.colorPrimary),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDateString() {
    String formattedDate = _selectedDate.toChineseDate();

    final today = _deviceTimeZone.now();
    if (today.year == _selectedDate.year &&
        today.month == _selectedDate.month &&
        today.day == _selectedDate.day) {
      formattedDate = "$formattedDate | 今天";
    }
    return formattedDate;
  }

  void _onPickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null ||
        (pickedDate.year == _selectedDate.year &&
            pickedDate.month == _selectedDate.month &&
            pickedDate.day == _selectedDate.day)) {
      return;
    }

    _dateSelectionGeneration += 1;
    setState(() {
      _selectedDate = pickedDate;
      _recordIndexPacket = null;
      _eventsLoading = true;
    });
    await _loadRecordIndex();
  }

  Widget _listContainer() {
    if (_eventsLoading) {
      return createCenterLoading(size: 20.0);
    }

    if (_recordIndexPacket?.list.isEmpty ?? true) return _emptyTips();

    return _eventList();
  }

  ListView _eventList() {
    return ListView.builder(
        itemCount: _recordIndexPacket?.list.length ?? 0,
        itemBuilder: (context, index) {
          return _buildTapItem(
            _recordIndexPacket!.list[index],
            isFirst: index == 0,
            isLast: index == _recordIndexPacket!.list.length - 1,
          );
        });
  }

  Widget _buildTapItem(CloudRecordIndex record,
      {bool isFirst = false, bool isLast = false}) {
    return _buildItem(record, isFirst: isFirst, isLast: isLast);
  }

  Widget _buildItem(
    CloudRecordIndex record, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isCurrentDownload =
        _isDownloading && _downloadingRecordKey == _recordDownloadKey(record);
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: isFirst ? 16 : 8,
        bottom: isLast ? 16 : 8,
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud,
                            size: 18,
                            color: SampleThemeConfigure.colorPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${_deviceTimeZone.formatTimestamp(record.startTimestampSecond * 1000)} - ${_deviceTimeZone.formatTimestamp(record.endTimestampSecond * 1000)}",
                              style: const TextStyle(
                                color: SampleThemeConfigure.colorTextPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "时长: ${_formatDuration(record.durationSecond)}",
                        style: const TextStyle(
                          color: SampleThemeConfigure.colorTextHint,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _onPlayRecord(record),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SampleThemeConfigure.colorPrimary
                              .withOpacity(0.15),
                          foregroundColor: SampleThemeConfigure.colorPrimary
                              .withOpacity(0.85),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text("播放", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CloudReplayDownloadButton(
                      key: ValueKey(
                        'cloud-replay-download-${record.startTimestampSecond}',
                      ),
                      downloadInProgress: _isDownloading,
                      currentDownload: isCurrentDownload,
                      cancelEnabled: _downloadCanCancel,
                      progress: isCurrentDownload ? _totalDownloadProgress : 0,
                      onDownload: () => _onDownloadRecord(record),
                      onCancel: _cancelDownload,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 0) {
      return "";
    }

    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    final List<String> parts = [];

    if (hours > 0) {
      parts.add('$hours小时');
    }
    if (minutes > 0 || hours > 0) {
      parts.add('$minutes分钟');
    }
    parts.add('$remainingSeconds秒');

    return parts.join('');
  }

  Widget _emptyTips() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_note,
              size: 50, color: SampleThemeConfigure.colorPrimary),
          SizedBox(height: 10),
          Text(
            '没有录像',
            style: TextStyle(
              fontSize: 14,
              color: SampleThemeConfigure.colorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerBody(double screenWidth) {
    if (_cameraCount == 4) {
      return buildFourCameraGrid([
        _player.texture(),
        _player1!.texture(),
        _player2!.texture(),
        _player3!.texture(),
      ]);
    }
    final double smallPlayerWidth = (screenWidth * 0.4).clamp(120.0, 180.0);
    final double smallPlayerHeight = smallPlayerWidth * 9 / 16;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: SampleThemeConfigure.colorVideoBackground),
        ),
        _player.texture(),
        if (_cameraCount > 1 && _player1 != null)
          Positioned(
            left: 2,
            bottom: 2,
            width: smallPlayerWidth,
            height: smallPlayerHeight,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _player1!.texture(),
              ),
            ),
          ),
        if (_cameraCount > 2 && _player2 != null)
          Positioned(
            right: 2,
            bottom: 2,
            width: smallPlayerWidth,
            height: smallPlayerHeight,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _player2!.texture(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;
    _cameraCount = widget.cameraCount;
    _deviceTimeZone = CloudReplayTimeZone.clientLocal();
    _selectedDate = _deviceTimeZone.now();
    _preparePlayer();

    final prefetchedTimezone = widget.deviceTimezone;
    if (prefetchedTimezone != null) {
      _applyDeviceTimezone(prefetchedTimezone, initializeDate: true);
      Logging.i(
        _tag,
        '[device_timezone] device_id=$_deviceId, source=list_cache, '
        'raw=${prefetchedTimezone.timezone}, '
        'device_time=${prefetchedTimezone.deviceTime}, '
        'offset_min=${_deviceTimeZone.offset.inMinutes}',
      );
      unawaited(_loadRecordIndex());
    } else {
      unawaited(_loadDeviceTimezoneAndRecords());
    }
  }

  @override
  void dispose() {
    Logging.i(_tag, "dispose ...");

    WidgetsBinding.instance.removeObserver(this);

    // Native stop/destroy operations may synchronously emit callbacks. Detach
    // UI listeners before releasing the players so they cannot call setState.
    _player.onRenderState = (_) {};
    _player.onPresentationTimestamp = (_) {};
    _player.onUniversalTimestamp = (_) {};

    _player.mute(true);
    _player1?.mute(true);
    _player2?.mute(true);
    _player3?.mute(true);

    _player3?.stop();
    _player2?.stop();
    _player1?.stop();
    _stream.stop();
    _player.stop();
    _isDownloading = false;
    for (final capture in _downloadCaptures) {
      capture.onState = (_, __) {};
      capture.onProgress = (_) {};
      capture.stop();
    }
    _streamOfDownload.onRetrieveError = (_) {};
    _streamOfDownload.onComplete = () {};
    _streamOfDownload.stop();

    _player3?.destroy();
    _player2?.destroy();
    _player1?.destroy();
    _player.destroy();
    _stream.destroy();
    _streamOfDownload.destroy();

    Logging.i(_tag, "dispose done");
    super.dispose();
  }

  void _preparePlayer() {
    _stream = CloudReplayStream.create(_deviceId);
    _stream.onChunkNotFound = (timestampS) {
      // handle chunk not found
    };

    _streamOfDownload = CloudReplayStream.create(_deviceId);
    _streamOfDownload.onComplete = () {
      if (!mounted || !_isDownloading) return;
      Logging.i(
        _tag,
        "[download] stream completed, record_key=$_downloadingRecordKey",
      );
    };
    _streamOfDownload.onRetrieveError = (errorCode) {
      if (!mounted) return;
      _failDownload("Video download failed ($errorCode)");
    };

    _downloadCaptures = List<CloudReplayCapture>.generate(_cameraCount, (
      cameraIndex,
    ) {
      final capture = CloudReplayCapture.create(
        _deviceId,
        _streamOfDownload,
        cameraIndex: cameraIndex,
      );
      capture.onState = (state, errorCode) {
        if (!mounted) return;
        Logging.i(
          _tag,
          "[download] capture state changed, record_key=$_downloadingRecordKey, camera_index=$cameraIndex, state=$state, error_code=$errorCode",
        );
        if (state == CloudReplayCaptureState.completed) {
          _completedDownloadCameras.add(cameraIndex);
          if (_completedDownloadCameras.length == _cameraCount) {
            _completeDownload();
          }
        } else if (state == CloudReplayCaptureState.error) {
          _failDownload("Video export failed ($errorCode)");
        }
      };
      capture.onProgress = (progress) {
        if (!mounted || !_isDownloading) return;
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
    });

    _stream.onComplete = () => Logging.i(
          _tag,
          '[stream_completed] generation=${_playbackTimeline.generation}',
        );

    final providerPtr = _stream.provider(cameraIndex: 0)!;

    _player = _createSamplePlayer();
    _player.prepare(providerPtr);
    _player.onRenderState = (state) {
      if (!mounted) return;
      final previousTimestampInMs = _currentTimestampInMs;
      if (state == RenderState.completed && !_canAcceptPlaybackCompleted()) {
        Logging.w(
          _tag,
          '[playback_completed_ignored] current_uts_ms='
          '$previousTimestampInMs, last_uts_ms=$_lastAcceptedUtsInMs, '
          'start_uts_ms=$_currentPartStartTimestampInMs, '
          'end_uts_ms=$_currentPartEndTimestampInMs',
        );
        return;
      }
      setState(() {
        _currentRenderState = state;
        if (state == RenderState.completed &&
            _currentPartEndTimestampInMs > 0) {
          _currentTimestampInMs = _currentPartEndTimestampInMs;
          _seekPosition =
              (_currentPartEndTimestampInMs - _currentPartStartTimestampInMs)
                  .clamp(0, 0x7fffffff)
                  .toInt();
          _seekDragging = false;
        }
      });
      if (state == RenderState.completed) {
        Logging.i(
          _tag,
          '[playback_completed] current_uts_ms=$previousTimestampInMs, '
          'end_uts_ms=$_currentPartEndTimestampInMs, '
          'remaining_ms=${math.max(0, _currentPartEndTimestampInMs - previousTimestampInMs)}, '
          'last_pts_ms=$_lastAcceptedPtsInMs, '
          'last_uts_ms=$_lastAcceptedUtsInMs, '
          'device_tz_offset_min=${_deviceTimeZone.offset.inMinutes}, '
          'device_tz_raw=${_deviceTimeZone.rawValue}',
        );
      }
    };

    if (_cameraCount > 1) {
      final providerPtr1 = _stream.provider(cameraIndex: 1)!;
      _player1 = _createSamplePlayer();
      _player1!.prepare(providerPtr1);
      _player1!.enableAudio(false);
      _player1!.bindingPrimaryPlayer(_player);
    }

    if (_cameraCount > 2) {
      final providerPtr2 = _stream.provider(cameraIndex: 2)!;
      _player2 = _createSamplePlayer();
      _player2!.prepare(providerPtr2);
      _player2!.enableAudio(false);
      _player2!.bindingPrimaryPlayer(_player);
    }

    if (_cameraCount > 3) {
      final providerPtr3 = _stream.provider(cameraIndex: 3)!;
      _player3 = _createSamplePlayer();
      _player3!.prepare(providerPtr3);
      _player3!.enableAudio(false);
      _player3!.bindingPrimaryPlayer(_player);
    }
  }

  void _bindPlaybackTimeline(int generation) {
    _pendingPtsInMs = null;
    _lastAcceptedPtsInMs = null;
    _lastAcceptedUtsInMs = null;
    _player.onPresentationTimestamp = (timestamp) {
      if (generation == _playbackTimeline.generation) {
        _pendingPtsInMs = timestamp;
      }
    };
    _player.onUniversalTimestamp = (timestamp) {
      final ptsInMs = _pendingPtsInMs;
      final decision = _playbackTimeline.evaluate(
        ptsInMs: ptsInMs ?? 0,
        utsInMs: timestamp,
        callbackGeneration: generation,
      );
      if (decision.timestampInMs == null) {
        Logging.w(
            _tag,
            '[uts_drop] generation=$generation, '
            'reason=${decision.dropReason}, pts_ms=$ptsInMs, uts_ms=$timestamp, '
            'dropped=${decision.droppedCount}');
        return;
      }
      _lastAcceptedPtsInMs = ptsInMs;
      _lastAcceptedUtsInMs = timestamp;
      if (decision.firstAccepted) {
        Logging.i(
            _tag,
            '[pts_gate_opened] generation=$generation, '
            'pts_ms=$ptsInMs, uts_ms=$timestamp');
      }
      final anomaly = decision.utsAnomaly;
      if (anomaly != null) {
        Logging.w(
            _tag,
            '[uts_anomaly] generation=$generation, '
            'kind=${anomaly.kind}, previous_uts_ms=${anomaly.previousTimestampInMs}, '
            'uts_ms=${anomaly.timestampInMs}, pts_delta_ms=${anomaly.ptsDeltaInMs}, '
            'uts_delta_ms=${anomaly.utsDeltaInMs}, count=${anomaly.count}');
      }
      if (!mounted || generation != _playbackTimeline.generation) return;
      setState(() {
        _currentTimestampInMs = decision.timestampInMs!;
      });
    };
  }

  bool _canAcceptPlaybackCompleted() {
    return CloudReplayCompletionPolicy.matchesActiveRecord(
      recordSelected: _recordClicked,
      startTimestampInMs: _currentPartStartTimestampInMs,
      endTimestampInMs: _currentPartEndTimestampInMs,
      lastPresentedTimestampInMs: _lastAcceptedUtsInMs ?? 0,
      toleranceInMs: _completionTimestampToleranceMs,
    );
  }

  Future<void> _loadDeviceTimezoneAndRecords() async {
    final dateSelectionGeneration = _dateSelectionGeneration;
    try {
      final response = await SpecService.timezone(_deviceId);
      if (response.success && response.data != null) {
        final timezone = response.data!;
        _applyDeviceTimezone(
          timezone,
          initializeDate: _dateSelectionGeneration == dateSelectionGeneration,
        );
        Logging.i(
          _tag,
          '[device_timezone] device_id=$_deviceId, '
          'raw=${timezone.timezone}, device_time=${timezone.deviceTime}, '
          'offset_min=${_deviceTimeZone.offset.inMinutes}, '
          'source=${_deviceTimeZone.source}, '
          'client_tz=${DateTime.now().timeZoneName}, '
          'client_offset_min=${DateTime.now().timeZoneOffset.inMinutes}',
        );
      } else {
        Logging.w(
          _tag,
          '[device_timezone] device_id=$_deviceId, fallback=client, '
          'code=${response.code}, message=${response.message}',
        );
      }
    } catch (error, stackTrace) {
      Logging.e(
        _tag,
        '[device_timezone] device_id=$_deviceId, fallback=client, '
        'error=$error\n$stackTrace',
      );
    }
    if (!mounted) return;
    setState(() {});
    await _loadRecordIndex();
  }

  void _applyDeviceTimezone(Timezone timezone, {required bool initializeDate}) {
    _deviceTimeRaw = timezone.deviceTime;
    _deviceTimeZone = CloudReplayTimeZone.resolve(
      rawValue: timezone.timezone,
      deviceTime: timezone.deviceTime,
      fallbackOffset: DateTime.now().timeZoneOffset,
    );
    if (initializeDate) {
      _selectedDate = _deviceTimeZone.now();
    }
  }

  Future<void> _loadRecordIndex() async {
    final requestGeneration = ++_recordIndexRequestGeneration;
    final date = _selectedDate.toStandardDate();
    Logging.i(
      _tag,
      '[record_index] date=$date, device_tz_offset_min='
      '${_deviceTimeZone.offset.inMinutes}, '
      'device_tz_raw=${_deviceTimeZone.rawValue}',
    );
    try {
      final response = await StorageService.listRecords(_deviceId, date);
      if (!mounted || requestGeneration != _recordIndexRequestGeneration) {
        Logging.i(
          _tag,
          '[record_index_ignored] date=$date, request_generation='
          '$requestGeneration, latest_generation=$_recordIndexRequestGeneration',
        );
        return;
      }
      if (response.success) {
        _recordIndexPacket = response.data;
        if (_recordIndexPacket?.list.isNotEmpty == true) {
          _recordIndexPacket!.list = _recordIndexPacket!.list.reversed.toList();
        }
      } else {
        _recordIndexPacket = null;
        Logging.w(
          _tag,
          '[record_index_failed] date=$date, code=${response.code}, '
          'message=${response.message}',
        );
      }

      setState(() {
        _eventsLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted || requestGeneration != _recordIndexRequestGeneration) {
        return;
      }
      Logging.e(
        _tag,
        '[record_index_error] date=$date, error=$error\n$stackTrace',
      );
      setState(() {
        _recordIndexPacket = null;
        _eventsLoading = false;
      });
    }
  }

  void _onPlayRecord(CloudRecordIndex record) async {
    final startTimestampInMs = record.startTimestampSecond * 1000;
    final endTimestampInMs = record.endTimestampSecond * 1000;

    // Drain callbacks from the previous record before binding the next
    // playback generation.
    _player.stop();
    _player1?.stop();
    _player2?.stop();
    _player3?.stop();
    _stream.stop();

    final generation = _playbackTimeline.begin(
      startTimestampInMs: startTimestampInMs,
      endTimestampInMs: endTimestampInMs,
      minimumTimestampInMs: startTimestampInMs,
    );
    _bindPlaybackTimeline(generation);
    setState(() {
      _recordClicked = true;
      _currentRenderState = RenderState.buffering;
      _seekDragging = false;
      _seekPosition = 0;
      _currentPartStartTimestampInMs = startTimestampInMs;
      _currentPartEndTimestampInMs = endTimestampInMs;
      _currentTimestampInMs = startTimestampInMs;
    });

    _stream.prepare(
      record.startTimestampSecond,
      record.endTimestampSecond,
      record.storageId,
      fileNameList: record.isTimelapse ? record.files : null,
      replayMode: record.isTimelapse
          ? CloudReplayMode.timelapse
          : CloudReplayMode.normal,
    );
    _stream.start();

    _player.start();

    _player1?.start();

    _player2?.start();
    _player3?.start();

    Logging.i(
      _tag,
      '[play_record] generation=$generation, '
      'start_uts_ms=$_currentPartStartTimestampInMs, '
      'end_uts_ms=$_currentPartEndTimestampInMs, '
      'storage_id=${record.storageId}, '
      'device_tz_offset_min=${_deviceTimeZone.offset.inMinutes}, '
      'device_tz_raw=${_deviceTimeZone.rawValue}, '
      'device_time=$_deviceTimeRaw, '
      'client_tz=${DateTime.now().timeZoneName}',
    );
  }

  void _onDownloadRecord(CloudRecordIndex record) async {
    if (_isDownloading) return;
    final granted = await RuntimePermissions.accessGranted(
      PermissionType.gallery,
    );
    if (!granted) {
      final ret = await RuntimePermissions.requestAccess(
        PermissionType.gallery,
      );
      if (ret != PermissionState.granted) {
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
    setState(() {
      _isDownloading = true;
      _downloadCanCancel = false;
      _totalDownloadProgress = 0;
      _downloadingRecordKey = _recordDownloadKey(record);
    });
    _completedDownloadCameras.clear();
    _downloadProgress.clear();

    // Generate gallery name based on record timestamp and device info
    final dateTimeStr = _deviceTimeZone.formatFileTimestamp(
      record.startTimestampSecond * 1000,
    );

    _streamOfDownload.stop();
    final startResult = await _streamOfDownload.startDownload(
      record.startTimestampSecond,
      record.endTimestampSecond,
      record.storageId,
      fileNameList: record.isTimelapse ? record.files : null,
    );
    if (startResult.type == CloudReplayDownloadStartResultType.fileTooLong) {
      if (!mounted) return;
      _failDownload(_downloadStartErrorMessage(startResult));
      return;
    }
    if (!startResult.success) {
      if (!mounted) return;
      _failDownload(_downloadStartErrorMessage(startResult));
      return;
    }

    for (var cameraIndex = 0;
        cameraIndex < _downloadCaptures.length;
        cameraIndex++) {
      if (!mounted || !_isDownloading) return;
      final started = await _downloadCaptures[cameraIndex].start(
        record.startTimestampSecond,
        record.endTimestampSecond,
        galleryName: "$dateTimeStr-$_deviceName-camera$cameraIndex.mp4",
      );
      if (!mounted || !_isDownloading) return;
      if (!started) {
        _failDownload("Unable to create video export");
        return;
      }
    }
    setState(() {
      _downloadCanCancel = true;
    });
  }

  void _completeDownload() {
    if (!mounted || !_isDownloading) return;
    Logging.i(_tag, "[download] completed, record_key=$_downloadingRecordKey");
    _stopDownload();
    SnackTips.show(context, "Video download completed");
  }

  void _failDownload(String message) {
    if (!mounted || !_isDownloading) return;
    Logging.i(
      _tag,
      "[download] failed, record_key=$_downloadingRecordKey, message=$message",
    );
    _stopDownload();
    SnackTips.show(context, message);
  }

  void _cancelDownload() {
    if (!mounted || !_isDownloading || !_downloadCanCancel) return;
    Logging.i(_tag, "[download] cancelled, record_key=$_downloadingRecordKey");
    _stopDownload();
    SnackTips.show(context, "Video download cancelled");
  }

  void _stopDownload() {
    for (final capture in _downloadCaptures) {
      capture.stop();
    }
    _streamOfDownload.stop();
    _completedDownloadCameras.clear();
    _downloadProgress.clear();
    setState(() {
      _isDownloading = false;
      _downloadCanCancel = false;
      _totalDownloadProgress = 0;
      _downloadingRecordKey = null;
    });
  }

  String _downloadStartErrorMessage(CloudReplayDownloadStartResult result) {
    switch (result.type) {
      case CloudReplayDownloadStartResultType.networkError:
        return "Unable to check download permission (${result.errorCode})";
      case CloudReplayDownloadStartResultType.noPermitted:
        return "Cloud video download is not permitted";
      case CloudReplayDownloadStartResultType.invalidParameter:
        return "Invalid cloud video download parameters";
      case CloudReplayDownloadStartResultType.invalidResponse:
        return "Invalid download configuration response";
      case CloudReplayDownloadStartResultType.fileTooLong:
        return "Video is ${result.requestedDurationSeconds}s; maximum is ${result.permittedDurationSeconds}s";
      case CloudReplayDownloadStartResultType.success:
        return "";
    }
  }

  String _recordDownloadKey(CloudRecordIndex record) =>
      "${record.storageId}:${record.startTimestampSecond}:${record.endTimestampSecond}";
}

class _CloudReplaySliderThumbShape extends SliderComponentShape {
  static const double _width = 36;
  static const double _height = 24;

  const _CloudReplaySliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(_width, _height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = Rect.fromCenter(
      center: center,
      width: _width,
      height: _height,
    );
    final shape = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_height / 2),
    );
    final path = Path()..addRRect(shape);
    context.canvas.drawShadow(path, Colors.black45, 4, true);
    context.canvas.drawRRect(
      shape,
      Paint()..color = sliderTheme.thumbColor ?? Colors.white,
    );
  }
}

class _CloudReplaySliderTrackShape extends SliderTrackShape {
  const _CloudReplaySliderTrackShape();

  @override
  bool get isRounded => true;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 0;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - height) / 2,
      parentBox.size.width,
      height,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (trackRect.height <= 0) return;
    final paintedTrackRect = Rect.fromLTWH(
      offset.dx,
      trackRect.top,
      parentBox.size.width,
      trackRect.height,
    );

    final activeColor = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    ).evaluate(enableAnimation)!;
    final inactiveColor = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    ).evaluate(enableAnimation)!;
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = trackRect.height
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = trackRect.height
      ..strokeCap = StrokeCap.round;

    context.canvas.drawLine(
      paintedTrackRect.centerLeft,
      paintedTrackRect.centerRight,
      inactivePaint,
    );
    context.canvas.drawLine(
      textDirection == TextDirection.ltr
          ? paintedTrackRect.centerLeft
          : paintedTrackRect.centerRight,
      thumbCenter,
      activePaint,
    );
  }
}
