part of '../../rapid_kit_sample_pages.dart';

class LocalReplayTimelinePanel extends StatefulWidget {
  final DateTime selectedDate;
  final int total;
  final bool loading;
  final String? error;
  final bool downloading;
  final int? downloadingRecordTimestamp;
  final double downloadProgress;
  final List<RecordIndex> records;
  final String? timestampLabel;
  final int currentTimestampInMs;
  final VoidCallback onRetryLoad;
  final void Function(RecordIndex record) onSeek;
  final void Function(
    int timestampSecond,
    int? startTimestampSecond,
    int? endTimestampSecond,
  )? onSeekTimestamp;
  final ValueChanged<int>? onUnavailableTimestamp;
  final bool allowUnboundedAovSeek;
  final ValueChanged<RecordIndex>? onDownloadRecord;
  final VoidCallback? onPickDate;
  final ValueChanged<DateTime>? onDateChanged;

  const LocalReplayTimelinePanel({
    super.key,
    required this.selectedDate,
    required this.total,
    required this.loading,
    this.error,
    this.downloading = false,
    this.downloadingRecordTimestamp,
    this.downloadProgress = 0,
    required this.records,
    this.timestampLabel,
    this.currentTimestampInMs = 0,
    required this.onRetryLoad,
    required this.onSeek,
    this.onSeekTimestamp,
    this.onUnavailableTimestamp,
    this.allowUnboundedAovSeek = false,
    this.onDownloadRecord,
    this.onPickDate,
    this.onDateChanged,
  });

  @override
  State<LocalReplayTimelinePanel> createState() =>
      _LocalReplayTimelinePanelState();
}

class _LocalReplayTimelinePanelState extends State<LocalReplayTimelinePanel> {
  static const int _secondsPerDay = 24 * 60 * 60;
  static const List<double> _zoomScales = [0.2, 0.5, 1, 2, 4];

  final ScrollController _scrollController = ScrollController();
  Timer? _seekFollowTimeout;
  bool _userScrolling = false;
  bool _programmaticScroll = false;
  bool _didInitialPosition = false;
  bool _syncScheduled = false;
  int _zoomIndex = 0;
  int? _previewSecondOfDay;
  int? _awaitingSeekTimestamp;
  int? _unavailableTimestamp;

  double get _pixelsPerSecond => _zoomScales[_zoomIndex];

  @override
  void initState() {
    super.initState();
    _schedulePlaybackSync();
  }

  @override
  void didUpdateWidget(covariant LocalReplayTimelinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dateChanged = !LocalReplayUiHelpers.isSameDate(
        oldWidget.selectedDate, widget.selectedDate);
    if (dateChanged) {
      _didInitialPosition = false;
      _previewSecondOfDay = null;
      _awaitingSeekTimestamp = null;
      _unavailableTimestamp = null;
      _seekFollowTimeout?.cancel();
    }
    final playbackSecondChanged = oldWidget.currentTimestampInMs ~/ 1000 !=
        widget.currentTimestampInMs ~/ 1000;
    if (dateChanged ||
        playbackSecondChanged ||
        oldWidget.records != widget.records) {
      _schedulePlaybackSync();
    }
  }

  @override
  void dispose() {
    _seekFollowTimeout?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F7F7),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final today = DateTime.now();
    final canMoveForward = widget.selectedDate
        .isBefore(DateTime(today.year, today.month, today.day));
    final status = widget.loading
        ? 'Loading records...'
        : widget.error != null
            ? 'Query failed'
            : '${widget.total} records';
    return Container(
      key: const ValueKey('rapid-local-replay-timeline-header'),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: Row(
              children: [
                IconButton(
                  key:
                      const ValueKey('rapid-local-replay-previous-date-action'),
                  tooltip: '前一天',
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: SampleThemeConfigure.colorTextPrimary,
                  onPressed: widget.onDateChanged == null
                      ? null
                      : () => widget.onDateChanged!(DateTime(
                            widget.selectedDate.year,
                            widget.selectedDate.month,
                            widget.selectedDate.day - 1,
                          )),
                ),
                Expanded(
                  child: TextButton.icon(
                    key:
                        const ValueKey('rapid-local-replay-date-picker-action'),
                    onPressed: widget.onPickDate,
                    icon: const Icon(Icons.calendar_month_outlined, size: 19),
                    label: Text(
                      LocalReplayUiHelpers.formatDateLabel(
                          widget.selectedDate, today),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: SampleThemeConfigure.colorPrimary,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('rapid-local-replay-next-date-action'),
                  tooltip: '后一天',
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: SampleThemeConfigure.colorTextPrimary,
                  onPressed: canMoveForward && widget.onDateChanged != null
                      ? () => widget.onDateChanged!(DateTime(
                            widget.selectedDate.year,
                            widget.selectedDate.month,
                            widget.selectedDate.day + 1,
                          ))
                      : null,
                ),
              ],
            ),
          ),
          if (_crossDayPlaybackLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Playing $_crossDayPlaybackLabel',
                  key: const ValueKey('rapid-local-replay-cross-day-playback'),
                  style: const TextStyle(
                    color: SampleThemeConfigure.colorTextSub,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF55B9D8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '全天录像',
                style: TextStyle(
                  color: SampleThemeConfigure.colorTextPrimary,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: SampleThemeConfigure.colorTextSub,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildZoomButton(
                key: const ValueKey('rapid-local-replay-zoom-out'),
                tooltip: '缩小时间轴',
                icon: Icons.zoom_out_rounded,
                onPressed: _zoomIndex > 0 ? () => _changeZoom(-1) : null,
              ),
              _buildZoomButton(
                key: const ValueKey('rapid-local-replay-zoom-in'),
                tooltip: '放大时间轴',
                icon: Icons.zoom_in_rounded,
                onPressed: _zoomIndex < _zoomScales.length - 1
                    ? () => _changeZoom(1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        key: key,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 20),
        color: SampleThemeConfigure.colorTextPrimary,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBody() {
    if (widget.loading) {
      return createCenterLoading(
        size: 20.0,
        color: SampleThemeConfigure.colorPrimary,
      );
    }
    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: SampleThemeConfigure.colorTextSub, size: 28),
            const SizedBox(height: 8),
            Text(
              widget.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SampleThemeConfigure.colorTextPrimary,
                letterSpacing: 0,
              ),
            ),
            TextButton(
                onPressed: widget.onRetryLoad, child: const Text('Retry')),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineWidth = constraints.maxWidth * 0.57;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('rapid-local-replay-timeline-column'),
              width: timelineWidth,
              child: _buildTimeline(),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFD9E3E5),
            ),
            Expanded(child: _buildRecordList()),
          ],
        );
      },
    );
  }

  Widget _buildTimeline() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final contentHeight =
            _secondsPerDay * _pixelsPerSecond + viewportHeight;
        final playheadY = LocalReplayUiHelpers.timelinePlayheadY(
          secondOfDay: _displaySecondOfDay,
          pixelsPerSecond: _pixelsPerSecond,
          viewportHeight: viewportHeight,
        );
        return Semantics(
          key: const ValueKey('rapid-local-replay-timeline'),
          label: '全天录像时间轴',
          value: _formatSecondOfDay(_displaySecondOfDay),
          slider: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LocalReplayTimelinePainter(
                      selectedDate: widget.selectedDate,
                      records: widget.records,
                      pixelsPerSecond: _pixelsPerSecond,
                      centerSecondOfDay: _displaySecondOfDay,
                      playheadY: playheadY,
                    ),
                  ),
                ),
              ),
              NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: SingleChildScrollView(
                  key: const ValueKey('rapid-local-replay-timeline-scroll'),
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: contentHeight,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: playheadY.clamp(0, viewportHeight - 2),
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('rapid-local-replay-seek-indicator'),
                    height: 2,
                    color: const Color(0xFFFF6557),
                  ),
                ),
              ),
              if (widget.records.isEmpty)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        '当天没有录像',
                        key: ValueKey('rapid-local-replay-record-empty'),
                        style: TextStyle(
                          color: SampleThemeConfigure.colorTextSub,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 8,
                top: (playheadY - 19).clamp(8, viewportHeight - 46),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF245E68),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSecondStepButton(
                        key: const ValueKey(
                            'rapid-local-replay-seek-second-back'),
                        tooltip: '后退 1 秒',
                        icon: Icons.remove_rounded,
                        delta: -1,
                      ),
                      Text(
                        _formatSecondOfDay(_displaySecondOfDay),
                        key: const ValueKey(
                            'rapid-local-replay-seek-time-label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: 0,
                        ),
                      ),
                      _buildSecondStepButton(
                        key: const ValueKey(
                            'rapid-local-replay-seek-second-forward'),
                        tooltip: '前进 1 秒',
                        icon: Icons.add_rounded,
                        delta: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordList() {
    final records = _recordings;
    return ColoredBox(
      key: const ValueKey('rapid-local-replay-record-list'),
      color: const Color(0xFFFAFCFC),
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE1E7E8)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  size: 17,
                  color: Color(0xFFC96D4B),
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    '录像列表',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SampleThemeConfigure.colorTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  '${records.length}',
                  style: const TextStyle(
                    color: SampleThemeConfigure.colorTextSub,
                    fontSize: 10,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? _buildRecordEmpty()
                : ListView.separated(
                    key:
                        const ValueKey('rapid-local-replay-record-list-scroll'),
                    padding: const EdgeInsets.all(8),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (context, index) =>
                        _buildRecordListItem(records[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordListItem(RecordIndex record) {
    final eventName = LocalReplayUiHelpers.eventLabel(record.eventType).trim();
    final active = identical(record, _activeRecord);
    final currentDownload = widget.downloading &&
        record.startTimestampSecond == widget.downloadingRecordTimestamp;
    final progress = widget.downloadProgress.clamp(0.0, 1.0);
    final recordLabel = eventName.isEmpty ? '普通录像' : eventName;
    final identity = '${record.startTimestampSecond}-'
        '${record.endTimestampSecond}-${record.eventType}';
    return Material(
      key: ValueKey('rapid-local-replay-record-$identity'),
      color: active ? const Color(0xFFFFE6DD) : const Color(0xFFFFF2ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: active ? const Color(0xFFF09A78) : const Color(0xFFFFDDD1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('rapid-local-replay-record-seek-$identity'),
        onTap: () => _commitSeekTimestamp(
          record.startTimestampSecond,
          selectedRecord: record,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 4, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalReplayUiHelpers.formatRecordDateTime(
                  record.startTimestampSecond,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SampleThemeConfigure.colorTextPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '至 ${LocalReplayUiHelpers.formatRecordDateTime(record.endTimestampSecond)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SampleThemeConfigure.colorTextSub,
                  fontSize: 9,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${active ? '播放中 · ' : ''}'
                      '$recordLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFFB65335)
                            : SampleThemeConfigure.colorTextSub,
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: '下载 MP4',
                    child: IconButton(
                      key: ValueKey(
                          'rapid-local-replay-record-download-$identity'),
                      onPressed:
                          widget.downloading || widget.onDownloadRecord == null
                              ? null
                              : () => widget.onDownloadRecord!(record),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 32, height: 30),
                      visualDensity: VisualDensity.compact,
                      icon: currentDownload
                          ? Semantics(
                              label: 'Downloading',
                              value: '${(progress * 100).round()}%',
                              child: SizedBox.square(
                                key: ValueKey(
                                    'local-replay-download-progress-${record.startTimestampSecond}'),
                                dimension: 22,
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                          value: progress, strokeWidth: 2),
                                      Text('${(progress * 100).round()}',
                                          style: const TextStyle(fontSize: 8)),
                                    ]),
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      color: SampleThemeConfigure.colorPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: SampleThemeConfigure.colorTextHint,
            size: 28,
          ),
          SizedBox(height: 6),
          Text(
            '没有录像',
            key: ValueKey('rapid-local-replay-record-list-empty'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SampleThemeConfigure.colorTextSub,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondStepButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required int delta,
  }) {
    return SizedBox(
      width: 34,
      height: 38,
      child: IconButton(
        key: key,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 38),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18),
        color: Colors.white,
        onPressed: () => _nudgeSecond(delta),
      ),
    );
  }

  int get _displaySecondOfDay {
    if (_previewSecondOfDay != null) return _previewSecondOfDay!;
    final current = _currentSecondOfDay();
    if (current != null) return current;
    final first = LocalReplayUiHelpers.firstPlayableRecord(
        widget.records, widget.selectedDate);
    if (first == null) return 0;
    return (first.startTimestampSecond -
            LocalReplayUiHelpers.dayStartSecond(widget.selectedDate))
        .clamp(0, _secondsPerDay - 1);
  }

  String? get _crossDayPlaybackLabel {
    if (widget.currentTimestampInMs <= 0 || _currentSecondOfDay() != null) {
      return null;
    }
    return LocalReplayUiHelpers.formatRecordDateTime(
        widget.currentTimestampInMs ~/ 1000);
  }

  int get _displayTimestampSecond =>
      LocalReplayUiHelpers.dayStartSecond(widget.selectedDate) +
      _displaySecondOfDay;

  RecordIndex? _recordContaining(int timestampSecond) {
    if (widget.records.isEmpty) return null;
    RecordIndex? active;
    for (final record in widget.records) {
      if (record.endTimestampSecond <= record.startTimestampSecond ||
          timestampSecond < record.startTimestampSecond ||
          timestampSecond >= record.endTimestampSecond) {
        continue;
      }
      if (active == null ||
          record.startTimestampSecond > active.startTimestampSecond) {
        active = record;
      }
    }
    return active;
  }

  RecordIndex? get _activeRecord => _recordContaining(_displayTimestampSecond);

  List<RecordIndex> get _recordings {
    final records = widget.records
        .where(
            (record) => record.endTimestampSecond > record.startTimestampSecond)
        .toList();
    records.sort((first, second) =>
        first.startTimestampSecond.compareTo(second.startTimestampSecond));
    return records;
  }

  int? _currentSecondOfDay() {
    if (widget.currentTimestampInMs <= 0) return null;
    final current =
        DateTime.fromMillisecondsSinceEpoch(widget.currentTimestampInMs);
    if (!LocalReplayUiHelpers.isSameDate(current, widget.selectedDate)) {
      return null;
    }
    return current.hour * 3600 + current.minute * 60 + current.second;
  }

  void _changeZoom(int delta) {
    final nextIndex = (_zoomIndex + delta).clamp(0, _zoomScales.length - 1);
    if (nextIndex == _zoomIndex) return;
    final anchorSecond = _displaySecondOfDay;
    setState(() => _zoomIndex = nextIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final offset = (anchorSecond * _pixelsPerSecond)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      _programmaticScroll = true;
      _scrollController.jumpTo(offset);
      _programmaticScroll = false;
      _didInitialPosition = true;
    });
  }

  void _nudgeSecond(int delta) {
    final secondOfDay =
        (_displaySecondOfDay + delta).clamp(0, _secondsPerDay - 1);
    final dayStart = LocalReplayUiHelpers.dayStartSecond(widget.selectedDate);
    _commitSeekTimestamp(dayStart + secondOfDay);
  }

  void _schedulePlaybackSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted || !_scrollController.hasClients || _userScrolling) return;
      if (_unavailableTimestamp != null) return;
      final awaiting = _awaitingSeekTimestamp;
      if (awaiting != null) {
        final currentSeconds = widget.currentTimestampInMs ~/ 1000;
        if ((currentSeconds - awaiting).abs() > 3) return;
        _awaitingSeekTimestamp = null;
        _seekFollowTimeout?.cancel();
      }
      final target = _currentSecondOfDay() ?? _displaySecondOfDay;
      final offset = (target * _pixelsPerSecond)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      if (_didInitialPosition &&
          (_scrollController.offset - offset).abs() < 0.5) {
        if (_previewSecondOfDay != null) {
          setState(() => _previewSecondOfDay = null);
        }
        return;
      }
      _didInitialPosition = true;
      _programmaticScroll = true;
      _scrollController.jumpTo(offset);
      _programmaticScroll = false;
      if (_previewSecondOfDay != null) {
        setState(() => _previewSecondOfDay = null);
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_programmaticScroll || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userScrolling = true;
      _seekFollowTimeout?.cancel();
      _awaitingSeekTimestamp = null;
      _unavailableTimestamp = null;
      _updatePreview(notification.metrics.pixels);
    } else if (notification is ScrollUpdateNotification && _userScrolling) {
      _updatePreview(notification.metrics.pixels);
    } else if (notification is ScrollEndNotification && _userScrolling) {
      _updatePreview(notification.metrics.pixels);
      _userScrolling = false;
      _commitSeek();
    }
    return false;
  }

  void _updatePreview(double offset) {
    final seconds =
        (offset / _pixelsPerSecond).round().clamp(0, _secondsPerDay - 1);
    if (_previewSecondOfDay == seconds) return;
    setState(() => _previewSecondOfDay = seconds);
  }

  void _commitSeek() {
    final dayStart = LocalReplayUiHelpers.dayStartSecond(widget.selectedDate);
    final requested = dayStart + _displaySecondOfDay;
    _commitSeekTimestamp(requested);
  }

  void _commitSeekTimestamp(
    int requested, {
    RecordIndex? selectedRecord,
  }) {
    final dayStart = LocalReplayUiHelpers.dayStartSecond(widget.selectedDate);
    final dayEnd = dayStart + _secondsPerDay;
    final selected = requested.clamp(dayStart, dayEnd - 1);
    final selectedSecond = selected - dayStart;
    if (selectedSecond != _previewSecondOfDay) {
      setState(() => _previewSecondOfDay = selectedSecond);
      unawaited(_animateToSecond(selectedSecond));
    }

    final playable = LocalReplayUiHelpers.resolvePlayableTimestamp(
      widget.records,
      widget.selectedDate,
      selected,
      allowUnboundedAovDay: widget.allowUnboundedAovSeek,
    );
    if (playable == null) {
      _awaitingSeekTimestamp = null;
      _seekFollowTimeout?.cancel();
      _unavailableTimestamp = selected;
      if (widget.onUnavailableTimestamp != null) {
        widget.onUnavailableTimestamp!(selected);
      } else {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('该时间段没有录像')),
        );
      }
      return;
    }

    _unavailableTimestamp = null;
    _awaitingSeekTimestamp = playable;
    _seekFollowTimeout?.cancel();
    _seekFollowTimeout = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      _awaitingSeekTimestamp = null;
      _schedulePlaybackSync();
    });

    if (selectedRecord != null) {
      widget.onSeek(selectedRecord);
      return;
    }
    if (widget.onSeekTimestamp != null) {
      if (widget.allowUnboundedAovSeek) {
        widget.onSeekTimestamp!(playable, null, null);
        return;
      }
      final containingRecord = _recordContaining(playable);
      widget.onSeekTimestamp!(
        playable,
        containingRecord?.startTimestampSecond,
        containingRecord?.endTimestampSecond,
      );
      return;
    }
    for (final record in widget.records) {
      if (record.startTimestampSecond <= playable &&
          playable < record.endTimestampSecond) {
        widget.onSeek(record);
        return;
      }
    }
  }

  Future<void> _animateToSecond(int secondOfDay) async {
    if (!_scrollController.hasClients) return;
    final offset = (secondOfDay * _pixelsPerSecond)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _programmaticScroll = true;
    try {
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } finally {
      _programmaticScroll = false;
    }
  }

  String _formatSecondOfDay(int seconds) {
    final value = seconds.clamp(0, _secondsPerDay - 1);
    final hour = value ~/ 3600;
    final minute = value % 3600 ~/ 60;
    final second = value % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')}';
  }
}

class _LocalReplayTimelinePainter extends CustomPainter {
  final DateTime selectedDate;
  final List<RecordIndex> records;
  final double pixelsPerSecond;
  final int centerSecondOfDay;
  final double playheadY;

  const _LocalReplayTimelinePainter({
    required this.selectedDate,
    required this.records,
    required this.pixelsPerSecond,
    required this.centerSecondOfDay,
    required this.playheadY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const rulerX = 78.0;
    const recordStripLeft = 82.0;
    const recordStripRight = 90.0;
    const recordAreaLeft = 92.0;
    final dayStart = LocalReplayUiHelpers.dayStartSecond(selectedDate);
    final dayEnd = dayStart + 24 * 60 * 60;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF2F4),
    );
    canvas.drawLine(
      const Offset(rulerX, 0),
      Offset(rulerX, size.height),
      Paint()
        ..color = const Color(0xFFBDD1D6)
        ..strokeWidth = 1,
    );

    for (final record in records) {
      final start = math.max(record.startTimestampSecond, dayStart);
      final end = math.min(record.endTimestampSecond, dayEnd);
      if (end <= start) continue;
      final top =
          playheadY + (start - dayStart - centerSecondOfDay) * pixelsPerSecond;
      final bottom =
          playheadY + (end - dayStart - centerSecondOfDay) * pixelsPerSecond;
      if (bottom < 0 || top > size.height) continue;
      final color = record.eventType == 0
          ? const Color(0xFF55B9D8)
          : const Color(0xFFF2A65A);
      canvas.drawRect(
        Rect.fromLTRB(
          recordAreaLeft,
          top,
          size.width,
          math.max(top + 3, bottom),
        ),
        Paint()..color = color.withOpacity(0.14),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            recordStripLeft,
            top,
            recordStripRight,
            math.max(top + 3, bottom),
          ),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }

    final tickPaint = Paint()
      ..color = const Color(0xFF9CB6BC)
      ..strokeWidth = 1;
    final minorTickSeconds = _minorTickSeconds();
    final labelIntervalSeconds = _labelIntervalSeconds();
    final visibleStart = math.max(
      0,
      (centerSecondOfDay - playheadY / pixelsPerSecond).floor(),
    );
    final visibleEnd = math.min(
      24 * 60 * 60,
      (centerSecondOfDay + (size.height - playheadY) / pixelsPerSecond).ceil(),
    );
    final firstTick = visibleStart ~/ minorTickSeconds * minorTickSeconds;
    for (int second = firstTick;
        second <= visibleEnd;
        second += minorTickSeconds) {
      final y = playheadY + (second - centerSecondOfDay) * pixelsPerSecond;
      final isHour = second % 3600 == 0;
      final hasLabel = second % labelIntervalSeconds == 0;
      final isMediumTick = second % math.max(minorTickSeconds, 5) == 0;
      final tickStart = isHour
          ? rulerX - 15
          : hasLabel
              ? rulerX - 11
              : isMediumTick
                  ? rulerX - 7
                  : rulerX - 4;
      canvas.drawLine(Offset(tickStart, y), Offset(rulerX, y), tickPaint);
      if (!hasLabel) continue;
      final label = _formatTickLabel(second, showSeconds: pixelsPerSecond >= 2);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Color(0xFF789198),
            fontSize: pixelsPerSecond >= 2 ? 10 : 11,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(math.max(4, rulerX - 20 - textPainter.width),
            y - textPainter.height / 2),
      );
    }
    canvas.restore();
  }

  int _minorTickSeconds() {
    if (pixelsPerSecond >= 4) return 1;
    if (pixelsPerSecond >= 2) return 5;
    if (pixelsPerSecond >= 1) return 10;
    if (pixelsPerSecond >= 0.5) return 30;
    return 60;
  }

  int _labelIntervalSeconds() {
    if (pixelsPerSecond >= 4) return 15;
    if (pixelsPerSecond >= 2) return 30;
    if (pixelsPerSecond >= 1) return 60;
    if (pixelsPerSecond >= 0.5) return 2 * 60;
    return 10 * 60;
  }

  String _formatTickLabel(int secondOfDay, {required bool showSeconds}) {
    if (secondOfDay >= 24 * 60 * 60) {
      return showSeconds ? '24:00:00' : '24:00';
    }
    final hour = secondOfDay ~/ 3600;
    final minute = secondOfDay % 3600 ~/ 60;
    final second = secondOfDay % 60;
    final label = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
    return showSeconds ? '$label:${second.toString().padLeft(2, '0')}' : label;
  }

  @override
  bool shouldRepaint(covariant _LocalReplayTimelinePainter oldDelegate) {
    return oldDelegate.selectedDate != selectedDate ||
        oldDelegate.records != records ||
        oldDelegate.centerSecondOfDay != centerSecondOfDay ||
        oldDelegate.playheadY != playheadY ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond;
  }
}

class LocalReplayTimelineItem extends StatelessWidget {
  final RecordIndex record;
  final bool downloading;
  final double? downloadProgress;
  final VoidCallback onSeek;
  final VoidCallback onDownload;

  const LocalReplayTimelineItem({
    super.key,
    required this.record,
    required this.downloading,
    required this.downloadProgress,
    required this.onSeek,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(
          'rapid-local-replay-seek-${record.startTimestampSecond}',
        ),
        onTap: downloading ? null : onSeek,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: SampleThemeConfigure.colorSoftWhite,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      record.startTimestampSecond.toHHmmss(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${record.durationSecond}秒 ${LocalReplayUiHelpers.eventLabel(record.eventType)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: downloadProgress == null
                    ? "Download"
                    : "Downloading ${(_normalizedProgress * 100).round()}%",
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: OutlinedButton(
                    key: ValueKey(
                      'local-replay-download-${record.startTimestampSecond}',
                    ),
                    onPressed: downloading ? null : onDownload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.9),
                      side: BorderSide(color: Colors.white.withOpacity(0.45)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: downloadProgress == null
                        ? const Icon(Icons.download_rounded, size: 16)
                        : _buildDownloadProgress(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _normalizedProgress => downloadProgress!.clamp(0.0, 1.0);

  Widget _buildDownloadProgress() {
    final progress = _normalizedProgress;
    final percent = (progress * 100).round();
    return Semantics(
      label: "Downloading",
      value: "$percent%",
      child: SizedBox.square(
        key: ValueKey(
          'local-replay-download-progress-${record.startTimestampSecond}',
        ),
        dimension: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
            Text(
              "$percent",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
