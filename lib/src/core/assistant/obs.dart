part of '../library.dart';

class Obs {
  static List<ObsEvent> all(String deviceId) => RapidNativeObservability.all(deviceId);

  static ObsEvent? last(String deviceId) => RapidNativeObservability.latest(deviceId);

  static bool poll(String deviceId) => RapidNativeObservability.poll(deviceId);

  static RenderPerfStats? getRenderPerf(String deviceId) => RapidNativeObservability.getRenderPerf(deviceId);

  static String formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final millisecond = dateTime.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$millisecond';
  }
}

const Color _kObsActionColor = Color(0xFF1976D2);
const double _kObsActionIconSize = 13;
const double _kObsActionHeight = 18;
const double _kObsCollapsedStatsHeight = 26;
const StrutStyle _kObsActionStrutStyle = StrutStyle(fontSize: 9, height: 1, forceStrutHeight: true);
const TextHeightBehavior _kObsSingleLineHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
const TextStyle _kObsActionTextStyle = TextStyle(
  fontSize: 9,
  height: 1,
  fontWeight: FontWeight.w700,
  color: _kObsActionColor,
);

class ObsWidget extends StatefulWidget {
  final String deviceId;

  const ObsWidget({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<ObsWidget> createState() => _ObsWidgetState();
}

class _ObsWidgetState extends State<ObsWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final changed = Obs.poll(widget.deviceId);
      if (changed && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showObsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ObsBottomSheet(
        deviceId: widget.deviceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestEvent = Obs.last(widget.deviceId);

    return GestureDetector(
      onTap: _showObsPanel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.blue.withAlpha(128),
            width: 0.8,
          ),
        ),
        child: SizedBox(
          height: _kObsActionHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLevelIcon(latestEvent?.level ?? ObsLevel.info),
              const SizedBox(width: 5),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatEventText(latestEvent),
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEventText(ObsEvent? event) {
    if (event == null) return 'No events';

    final time = Obs.formatTime(event.timestamp);
    final label = event.label;
    final ext = event.ext.isNotEmpty ? ' ${event.ext}' : '';

    return '$time $label$ext';
  }

  Widget _buildLevelIcon(ObsLevel level) {
    Color color;
    IconData icon;

    switch (level) {
      case ObsLevel.info:
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
      case ObsLevel.warn:
        color = Colors.orange;
        icon = Icons.warning_outlined;
        break;
      case ObsLevel.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return SizedBox(
      width: 12,
      height: _kObsActionHeight,
      child: Center(
        child: Icon(
          icon,
          size: 12,
          color: color,
        ),
      ),
    );
  }

}

class _ObsBottomSheet extends StatefulWidget {
  final String deviceId;

  const _ObsBottomSheet({
    required this.deviceId,
  });

  @override
  State<_ObsBottomSheet> createState() => _ObsBottomSheetState();
}

class _ObsBottomSheetState extends State<_ObsBottomSheet> {
  List<ObsEvent> events = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final changed = Obs.poll(widget.deviceId);
      if (changed && mounted) {
        _loadEvents();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadEvents() {
    final newEvents = Obs.all(widget.deviceId);
    if (mounted) {
      setState(() {
        events = newEvents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 2 / 3,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildEventsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF659287).withAlpha(77), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.show_chart,
            color: Color(0xFF659287),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            '关键记录',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF659287),
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF659287).withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              iconSize: 18,
              color: const Color(0xFF659287),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          '暂无事件',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[events.length - 1 - index];
        return _buildEventItem(event);
      },
    );
  }

  Widget _buildEventItem(ObsEvent event) {
    Color color;
    IconData icon;

    switch (event.level) {
      case ObsLevel.info:
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
      case ObsLevel.warn:
        color = Colors.orange;
        icon = Icons.warning_outlined;
        break;
      case ObsLevel.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    final textStyle = TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: color.withAlpha(242),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              Obs.formatTime(event.timestamp),
              maxLines: 1,
              softWrap: false,
              style: textStyle.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatEventContent(event),
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventContent(ObsEvent event) {
    final parts = <String>[];
    if (event.group.isNotEmpty) parts.add('[${event.group}]');
    if (event.label.isNotEmpty) parts.add(event.label);
    if (event.ext.isNotEmpty && event.ext != event.label) parts.add(event.ext);
    return parts.isEmpty ? '-' : parts.join(' ');
  }
}

class RenderPerfWidget extends StatefulWidget {
  final Player player;
  final Pipe? pipe;
  final LiveStream? liveStream;
  final int cameraIndex;
  final Widget? trailing;
  final bool defaultExpanded;

  const RenderPerfWidget({
    Key? key,
    required this.player,
    this.pipe,
    this.liveStream,
    this.cameraIndex = 0,
    this.trailing,
    this.defaultExpanded = true,
  }) : super(key: key);

  @override
  State<RenderPerfWidget> createState() => _RenderPerfWidgetState();
}

class _RenderPerfWidgetState extends State<RenderPerfWidget> {
  _PlaybackDiagnosticsStats? _diagnosticsStats;
  Timer? _timer;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.defaultExpanded;
    _loadPerfData();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadPerfData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadPerfData() {
    _PlaybackDiagnosticsStats? stats;
    try {
      Map<String, dynamic> metricsJson = {};
      final jsonStr = widget.player.metricsSnapshot;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final obj = jsonDecode(jsonStr);
        if (obj is Map<String, dynamic>) {
          metricsJson = obj;
        }
      }

      final streamStats = _parsePlaybackStreamStatsString(widget.liveStream?.metricsSnapshot(cameraIndex: widget.cameraIndex));

      stats = _PlaybackDiagnosticsStats.fromJson(
        metricsJson,
        setup: _parsePerfStatsString(widget.pipe?.setupMetricsSnapshot),
        startup: _parsePerfStatsString(widget.player.startupMetricsSnapshot),
        firstPacket: _parsePerfStatsString(widget.liveStream?.firstPacketMetricsSnapshot(cameraIndex: widget.cameraIndex)),
        stream: streamStats,
      );
      if (!stats.hasSnapshot) {
        stats = null;
      }
    } catch (_) {
      stats = null;
    }

    if (mounted) {
      setState(() {
        _diagnosticsStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _diagnosticsStats;
    if ((stats == null || !stats.hasSnapshot) && widget.trailing == null) {
      return const SizedBox();
    }

    if (!_expanded) {
      return _buildCollapsed(stats);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _buildExpanded(stats),
    );
  }

  Widget _buildExpanded(_PlaybackDiagnosticsStats? stats) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRuntimeRows(stats),
          ),
        ),
        const SizedBox(width: 8),
        _buildToggleButton('收起', Icons.keyboard_arrow_up_rounded),
      ],
    );

    if (widget.trailing == null) {
      return content;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: content),
        const SizedBox(width: 10),
        Align(
          alignment: Alignment.center,
          child: widget.trailing!,
        ),
      ],
    );
  }

  Widget _buildCollapsed(_PlaybackDiagnosticsStats? stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          key: const ValueKey('rapid-live-stats-expand-action'),
          onTap: () => setState(() => _expanded = true),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: _kObsCollapsedStatsHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 15, color: Colors.black54),
                SizedBox(width: 6),
                Text(
                  '即时统计',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                  strutStyle: StrutStyle(fontSize: 10, height: 1, forceStrutHeight: true),
                  textHeightBehavior: _kObsSingleLineHeightBehavior,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        if (widget.trailing != null) Align(alignment: Alignment.center, child: widget.trailing!),
      ],
    );
  }

  Widget _buildToggleButton(String label, IconData icon) {
    return InkWell(
      key: ValueKey(label == '收起' ? 'rapid-live-stats-collapse-action' : 'rapid-live-stats-expand-action'),
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: _kObsActionHeight,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: _kObsActionColor.withAlpha(20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _kObsActionColor.withAlpha(89), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: _kObsActionTextStyle,
              strutStyle: _kObsActionStrutStyle,
              textHeightBehavior: _kObsSingleLineHeightBehavior,
            ),
            Icon(icon, size: _kObsActionIconSize, color: _kObsActionColor),
          ],
        ),
      ),
    );
  }

  String _decoderActualLabel(String actual) {
    switch (actual.toLowerCase()) {
      case 'android_mediacodec':
      case 'videotoolbox':
        return '硬解';
      case 'ffmpeg':
        return '软解';
      case '':
        return '--';
      default:
        return '后端 ${actual.trim()}';
    }
  }

  List<Widget> _buildRuntimeRows(_PlaybackDiagnosticsStats? stats) {
    final runtime = stats?.runtime;
    final stream = stats?.stream;
    final rows = <Widget>[
      _buildDenseRow('媒体参数', _formatParams(runtime, stream)),
      _buildDenseRow(
        '接收统计',
        _formatReceiveStats(stream),
        tooltip: '周期窗口内的音视频接收帧率和平均码率',
      ),
      _buildDenseRow('渲染帧率', '视频 ${_formatFps(runtime?.windowVideoFps)} · 音频回调 ${_formatFps(runtime?.windowAudioCallbackFps)}'),
      _buildDenseRow('本地缓冲', _formatPlaybackBuffer(runtime)),
      _buildDenseRow('首帧出图', _formatFirstFrameRenderCost(stats)),
      _buildDenseRow(
        '卡顿统计',
        _formatStutterStats(stats),
        tooltip: '两帧间隔超过 600 ms 记为一次卡顿',
      ),
    ];

    return rows;
  }

  Widget _buildDenseRow(String label, String value, {String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: _buildDenseLabel(label, tooltip),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, height: 1.25, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenseLabel(String label, String? tooltip) {
    final text = Text(
      '$label：',
      style: const TextStyle(fontSize: 10, height: 1.25, color: Color(0xFF659287), fontWeight: FontWeight.w700),
    );

    if (tooltip == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: text),
        Tooltip(
          message: tooltip,
          triggerMode: TooltipTriggerMode.tap,
          child: const Icon(Icons.help_outline_rounded, size: 11, color: Color(0xFF659287)),
        ),
      ],
    );
  }

  String _formatMs(int? value) => value == null || value < 0 ? '--' : '$value ms';

  String _formatPlaybackBuffer(_PlaybackRuntimeStats? runtime) {
    if (runtime == null) {
      return '--';
    }
    return '视频 ${_formatMs(runtime.currentVideoLatencyMs)} · 音频 ${_formatMs(runtime.currentAudioBufferMs)} · 阈值 ${_formatMs(runtime.currentWaterMarkMs)}';
  }

  String _formatFirstFrameRenderCost(_PlaybackDiagnosticsStats? stats) {
    final setup = stats?.setup;
    final startup = stats?.startup;
    final firstPacket = stats?.firstPacket;
    final connectionCost = setup?.totalDuration ?? 0;
    final connectedToRendered = _durationBetween(setup?.completedAt, startup?.completedAt);
    if (connectionCost <= 0) {
      return '--';
    }
    if (connectedToRendered > 0) {
      final total = connectionCost + connectedToRendered;
      return '${_formatMs(total)} = 连接 ${_formatMs(connectionCost)} + 出图 ${_formatMs(connectedToRendered)}';
    }

    final connectedToFirstPacket = _durationBetween(setup?.completedAt, firstPacket?.completedAt);
    if (connectedToFirstPacket > 0) {
      return '连接 ${_formatMs(connectionCost)} · 首帧 ${_formatMs(connectedToFirstPacket)} · 出图 --';
    }
    return '连接 ${_formatMs(connectionCost)} · 首帧 --';
  }

  int _durationBetween(int? startAt, int? endAt) {
    if (startAt == null || endAt == null || startAt <= 0 || endAt <= 0) {
      return 0;
    }
    final duration = endAt - startAt;
    return duration > 0 ? duration : 0;
  }

  String _formatParams(_PlaybackRuntimeStats? runtime, _PlaybackStreamStats? stream) {
    final resolution = _formatResolution(runtime?.renderVideoWidth ?? 0, runtime?.renderVideoHeight ?? 0);
    final videoCodec = _formatCodec(stream?.videoCodec ?? '');
    final audioCodec = _formatCodec(stream?.audioCodec ?? '');
    final clockMode = _formatClockMode(runtime?.clockMode);
    final params = <String>[
      resolution,
      videoCodec,
      audioCodec,
    ]..removeWhere((part) => part.isEmpty);
    final decoderActual = stream?.decoderActual.trim() ?? '';
    if (decoderActual.isNotEmpty || params.isNotEmpty) {
      params.add(_decoderActualLabel(decoderActual));
    }
    if (clockMode.isNotEmpty) {
      params.add(clockMode);
    }
    return params.isEmpty ? '--' : params.join(' · ');
  }

  String _formatClockMode(int? mode) {
    switch (mode) {
      case 0:
        return '音频主时钟';
      case 1:
        return '视频主时钟';
      default:
        return '';
    }
  }

  String _formatReceiveStats(_PlaybackStreamStats? stream) {
    if (stream == null) {
      return '--';
    }
    return '${_formatReceiveTrack('视频', stream.windowVideoFps, stream.windowVideoBitrateKbps)}'
        ' · ${_formatReceiveTrack('音频', stream.windowAudioFps, stream.windowAudioBitrateKbps)}';
  }

  String _formatReceiveTrack(String label, double? fps, int? bitrateKbps) {
    if (fps == null && bitrateKbps == null) {
      return '$label --';
    }
    return '$label ${_formatFps(fps)} ${_formatBitrate(bitrateKbps)}';
  }

  String _formatBitrate(int? value) {
    if (value == null || value < 0) return '--';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}Mbps';
    return '${value}Kbps';
  }

  String _formatFps(double? value) {
    if (value == null || value < 0) return '--';
    if (value == 0) return '0fps';
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}fps';
  }

  String _formatResolution(int width, int height) {
    if (width <= 0 || height <= 0) return '';
    return '${width}x$height';
  }

  String _formatCodec(String codec) {
    final value = codec.trim();
    if (value.isEmpty || value.toLowerCase() == 'unknown') return '';
    return value;
  }

  String _formatStutterStats(_PlaybackDiagnosticsStats? stats) {
    final runtime = stats?.runtime;
    final stutter = stats?.stutter;
    if (runtime == null || runtime.windowDurationMs <= 0 || stutter == null) {
      return '--';
    }

    return '${_formatWindowLabel(runtime)} · 发生 ${_formatStutterWindowCount(runtime, stutter)} 次视频卡顿';
  }

  int _formatStutterWindowCount(_PlaybackRuntimeStats runtime, _PlaybackStutterStats stutter) {
    final windowMinutes = runtime.windowDurationMs / 60000.0;
    if (windowMinutes <= 0 || stutter.windowDensity <= 0) return 0;
    return (stutter.windowDensity * windowMinutes).round();
  }

  String _formatWindowLabel(_PlaybackRuntimeStats? runtime) {
    final durationMs = runtime?.windowDurationMs ?? 0;
    if (durationMs <= 0) return '最近30秒';
    final seconds = (durationMs / 1000).round();
    return '最近${seconds <= 0 ? 30 : seconds}秒';
  }
}

class _PlaybackDiagnosticsStats {
  final RenderPerfStats? setup;
  final RenderPerfStats? startup;
  final RenderPerfStats? firstPacket;
  final _PlaybackRuntimeStats? runtime;
  final _PlaybackStreamStats? stream;
  final _PlaybackStutterStats? stutter;

  _PlaybackDiagnosticsStats({
    required this.setup,
    required this.startup,
    required this.firstPacket,
    required this.runtime,
    required this.stream,
    required this.stutter,
  });

  bool get hasSnapshot => setup != null || startup != null || firstPacket != null || runtime != null || stream != null || stutter != null;

  factory _PlaybackDiagnosticsStats.fromJson(
    Map<String, dynamic> json, {
    RenderPerfStats? setup,
    RenderPerfStats? startup,
    RenderPerfStats? firstPacket,
    _PlaybackStreamStats? stream,
  }) {
    final runtimeJson = _readMap(json['runtime']);
    final streamJson = _readMap(json['stream']);
    final stutterJson = _readMap(json['stutter']);
    final runtimeStream = streamJson == null ? null : _PlaybackStreamStats.fromJson(streamJson);
    final mergedStream = stream == null ? runtimeStream : stream.withPlayerFallback(runtimeStream);
    return _PlaybackDiagnosticsStats(
      setup: setup,
      startup: startup ?? _parseStartupStats(json),
      firstPacket: firstPacket,
      runtime: runtimeJson == null ? null : _PlaybackRuntimeStats.fromJson(runtimeJson),
      stream: mergedStream,
      stutter: stutterJson == null ? null : _PlaybackStutterStats.fromJson(stutterJson),
    );
  }
}

class _PlaybackRuntimeStats {
  final int windowDurationMs;
  final double? windowVideoFps;
  final double? windowAudioCallbackFps;
  final int windowVideoJankCount;
  final int windowAudioJankCount;
  final int windowBufferingCount;
  final bool currentBuffering;
  final int? currentVideoLatencyMs;
  final int? currentWaterMarkMs;
  final int currentPacketVideoDurationMs;
  final int? currentPacketAudioDurationMs;
  final int currentPacketVideoSize;
  final int currentPacketAudioSize;
  final int currentRenderQueueVideoSize;
  final int? currentRenderQueueAudioSize;
  final int specVideoIntervalMs;
  final int? specAudioIntervalMs;
  final int renderVideoWidth;
  final int renderVideoHeight;
  final int? clockMode;

  _PlaybackRuntimeStats({
    required this.windowDurationMs,
    required this.windowVideoFps,
    required this.windowAudioCallbackFps,
    required this.windowVideoJankCount,
    required this.windowAudioJankCount,
    required this.windowBufferingCount,
    required this.currentBuffering,
    required this.currentVideoLatencyMs,
    required this.currentWaterMarkMs,
    required this.currentPacketVideoDurationMs,
    required this.currentPacketAudioDurationMs,
    required this.currentPacketVideoSize,
    required this.currentPacketAudioSize,
    required this.currentRenderQueueVideoSize,
    required this.currentRenderQueueAudioSize,
    required this.specVideoIntervalMs,
    required this.specAudioIntervalMs,
    required this.renderVideoWidth,
    required this.renderVideoHeight,
    required this.clockMode,
  });

  int? get currentAudioBufferMs {
    if (currentPacketAudioDurationMs == null) {
      return null;
    }
    final renderDuration = specAudioIntervalMs != null && specAudioIntervalMs! > 0 && currentRenderQueueAudioSize != null
        ? currentRenderQueueAudioSize! * specAudioIntervalMs!
        : 0;
    return currentPacketAudioDurationMs! + renderDuration;
  }

  factory _PlaybackRuntimeStats.fromJson(Map<String, dynamic> json) {
    return _PlaybackRuntimeStats(
      windowDurationMs: _readInt(json, 'window_duration_ms'),
      windowVideoFps: _readOptionalDouble(json, 'window_video_fps'),
      windowAudioCallbackFps: _readOptionalDouble(json, 'window_audio_callback_fps'),
      windowVideoJankCount: _readInt(json, 'window_video_jank_count'),
      windowAudioJankCount: _readInt(json, 'window_audio_jank_count'),
      windowBufferingCount: _readInt(json, 'window_buffering_count'),
      currentBuffering: _readBool(json, 'current_buffering'),
      currentVideoLatencyMs: _readOptionalInt(json, 'current_video_latency_ms'),
      currentWaterMarkMs: _readOptionalInt(json, 'current_water_mark_ms'),
      currentPacketVideoDurationMs: _readInt(json, 'current_packet_video_duration_ms'),
      currentPacketAudioDurationMs: _readOptionalInt(json, 'current_packet_audio_duration_ms'),
      currentPacketVideoSize: _readInt(json, 'current_packet_video_size'),
      currentPacketAudioSize: _readInt(json, 'current_packet_audio_size'),
      currentRenderQueueVideoSize: _readInt(json, 'current_render_queue_video_size'),
      currentRenderQueueAudioSize: _readOptionalInt(json, 'current_render_queue_audio_size'),
      specVideoIntervalMs: _readInt(json, 'spec_video_interval_ms'),
      specAudioIntervalMs: _readOptionalInt(json, 'spec_audio_interval_ms'),
      renderVideoWidth: _readInt(json, 'render_video_width'),
      renderVideoHeight: _readInt(json, 'render_video_height'),
      clockMode: _readOptionalInt(json, 'clock_mode'),
    );
  }
}

class _PlaybackStreamStats {
  final double? windowVideoFps;
  final double? windowAudioFps;
  final int? windowVideoBitrateKbps;
  final int? windowAudioBitrateKbps;
  final String videoCodec;
  final String audioCodec;
  final String decoderActual;

  _PlaybackStreamStats({
    required this.windowVideoFps,
    required this.windowAudioFps,
    required this.windowVideoBitrateKbps,
    required this.windowAudioBitrateKbps,
    required this.videoCodec,
    required this.audioCodec,
    required this.decoderActual,
  });

  factory _PlaybackStreamStats.fromJson(Map<String, dynamic> json) {
    return _PlaybackStreamStats(
      windowVideoFps: _readOptionalDouble(json, 'window_video_fps'),
      windowAudioFps: _readOptionalDouble(json, 'window_audio_fps'),
      windowVideoBitrateKbps: _readOptionalInt(json, 'window_video_bitrate_kbps'),
      windowAudioBitrateKbps: _readOptionalInt(json, 'window_audio_bitrate_kbps'),
      videoCodec: _readString(json, 'video_codec'),
      audioCodec: _readString(json, 'audio_codec'),
      decoderActual: _readString(json, 'decoder_actual'),
    );
  }

  _PlaybackStreamStats withPlayerFallback(_PlaybackStreamStats? fallback) {
    if (fallback == null) {
      return this;
    }
    return _PlaybackStreamStats(
      windowVideoFps: windowVideoFps,
      windowAudioFps: windowAudioFps,
      windowVideoBitrateKbps: windowVideoBitrateKbps,
      windowAudioBitrateKbps: windowAudioBitrateKbps,
      videoCodec: _codecWithFallback(videoCodec, fallback.videoCodec),
      audioCodec: _codecWithFallback(audioCodec, fallback.audioCodec),
      decoderActual: decoderActual.trim().isNotEmpty ? decoderActual : fallback.decoderActual,
    );
  }

  String _codecWithFallback(String codec, String fallback) {
    final value = codec.trim();
    return value.isEmpty || value.toLowerCase() == 'unknown' ? fallback : codec;
  }
}

class _PlaybackStutterStats {
  final double windowRatio;
  final double windowDensity;
  final int windowPeakMs;

  _PlaybackStutterStats({
    required this.windowRatio,
    required this.windowDensity,
    required this.windowPeakMs,
  });

  factory _PlaybackStutterStats.fromJson(Map<String, dynamic> json) {
    return _PlaybackStutterStats(
      windowRatio: _readDouble(json, 'window_ratio'),
      windowDensity: _readDouble(json, 'window_density'),
      windowPeakMs: _readInt(json, 'window_peak_ms'),
    );
  }
}

RenderPerfStats? _parseStartupStats(Map<String, dynamic> json) {
  final startup = _readMap(json['startup']);
  if (startup != null) {
    return RenderPerfStats.fromJson(startup);
  }

  final startupByCamera = _readMap(json['startup_by_camera']);
  if (startupByCamera == null || startupByCamera.isEmpty) {
    return null;
  }

  final dynamic firstValue = startupByCamera.length == 1 ? startupByCamera.values.first : (startupByCamera['0'] ?? startupByCamera.values.first);
  final firstMap = _readMap(firstValue);
  return firstMap == null ? null : RenderPerfStats.fromJson(firstMap);
}

RenderPerfStats? _parsePerfStatsString(String? jsonStr) {
  if (jsonStr == null || jsonStr.isEmpty) {
    return null;
  }

  final obj = jsonDecode(jsonStr);
  final map = _readMap(obj);
  return map == null ? null : RenderPerfStats.fromJson(map);
}

_PlaybackStreamStats? _parsePlaybackStreamStatsString(String? jsonStr) {
  if (jsonStr == null || jsonStr.isEmpty) {
    return null;
  }

  final obj = jsonDecode(jsonStr);
  final map = _readMap(obj);
  return map == null ? null : _PlaybackStreamStats.fromJson(map);
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}

int? _readOptionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.round();
  return null;
}

double? _readOptionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return null;
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return 0;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is bool ? value : false;
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? '' : value.toString();
}
