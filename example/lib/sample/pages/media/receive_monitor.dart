// ignore_for_file: non_constant_identifier_names

part of '../rapid_kit_sample_pages.dart';

String receive_monitor_lane_status(Map<String, dynamic> data) {
  if (data['active'] == false) return 'Stopped';
  if (data['available'] == false) return 'Waiting for the first complete frame';
  if (data['baseline_supported'] == false) {
    return 'Receive statistics only; baseline alarms unsupported';
  }
  if (data['waiting_alarm'] == true) return 'No frames arriving';
  final reasons = [
    if (data['gap_alarm'] == true) 'Receive interval too long',
    if (data['rate_alarm'] == true) 'Receive rate dropped',
  ];
  if (reasons.isNotEmpty) return reasons.join(' / ');
  if (data['baseline_ready'] != true) {
    return 'Sampling baseline ${data['baseline_windows'] ?? 0}/10';
  }
  return 'Receiving normally';
}

class ReceiveMonitorPage extends StatefulWidget {
  final String deviceId;
  final int cameraCount;
  final String? deviceAbilities;

  const ReceiveMonitorPage(
      {super.key,
      required this.deviceId,
      required this.cameraCount,
      this.deviceAbilities});

  @override
  State<ReceiveMonitorPage> createState() => ReceiveMonitorState();
}

class ReceiveMonitorState extends State<ReceiveMonitorPage>
    with WidgetsBindingObserver {
  late final Pipe _pipe;
  LiveStream? _primary;
  LiveStream? _secondary;
  Timer? _timer;
  VoidCallback? _cancel_listener;
  bool _requested = false;
  String _status = 'Stopped';
  String _report = '';
  List<MapEntry<String, Map<String, dynamic>>> _lanes = [];
  List<Map<String, dynamic>> _events = [];
  late final bool _audio_enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio_enabled =
        DeviceAudioCapability.streamAudioEnabledFromDeviceAbilities(
            widget.deviceAbilities);
    _pipe = Pipe.createIndependent(widget.deviceId);
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _cancel_listener = _pipe.listen((state) {
      if (!mounted || !_requested) return;
      if (state == PipeState.established) {
        _begin_streams();
      } else if (state != PipeState.attempting) {
        _stop_monitor();
        setState(() => _status = 'Connection: $state');
      }
    });
  }

  LiveStream? _stream_for(int camera) =>
      widget.cameraCount == 2 && camera == 1 ? _secondary : _primary;

  void _start_monitor() {
    setState(() {
      _requested = true;
      _status = 'Connecting...';
      _lanes = [];
      _events = [];
      _report = '';
    });
    if (_pipe.isEstablished) {
      _begin_streams();
    } else {
      _pipe.establish();
    }
  }

  void _begin_streams() {
    if (_primary != null) return;
    _primary = LiveStream.createPrimary(_pipe, enableAudio: _audio_enabled);
    if (widget.cameraCount == 2) _secondary = LiveStream.createSecondary(_pipe);
    for (var camera = 0; camera < widget.cameraCount; camera++) {
      if (_stream_for(camera)?.receive_metrics(cameraIndex: camera) == null) {
        _stop_monitor();
        setState(() =>
            _status = 'Receive monitoring requires an updated native SDK.');
        return;
      }
    }
    for (var camera = 0; camera < widget.cameraCount; camera++) {
      final provider = _stream_for(camera)?.provider(cameraIndex: camera);
      if (provider == null || provider == ffi.nullptr) {
        _stop_monitor();
        setState(() => _status = 'Failed to register video channel.');
        return;
      }
    }
    _primary!.start();
    _secondary?.start();
    _refresh_report();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _refresh_report());
  }

  void _refresh_report() {
    final lanes = <MapEntry<String, Map<String, dynamic>>>[];
    for (var camera = 0; camera < widget.cameraCount; camera++) {
      final data = convert.jsonDecode(
              _stream_for(camera)?.receive_metrics(cameraIndex: camera) ?? '{}')
          as Map<String, dynamic>;
      if (data['video'] is Map<String, dynamic>) {
        lanes.add(MapEntry('Camera ${camera + 1}', data['video']));
      }
      if (camera == 0 && data['audio'] is Map<String, dynamic>) {
        lanes.add(MapEntry('Audio', data['audio']));
      }
    }
    final events = <Map<String, dynamic>>[];
    for (final lane in lanes) {
      for (final event in (lane.value['events'] as List? ?? [])) {
        events.add({...event as Map<String, dynamic>, 'lane': lane.key});
      }
    }
    events.sort((a, b) => ((b['session'] as num) + (b['elapsed_ms'] as num))
        .compareTo((a['session'] as num) + (a['elapsed_ms'] as num)));
    setState(() {
      _status = 'Connected';
      _lanes = lanes;
      _events = events.take(50).toList();
      _report = [
        for (final lane in lanes)
          '${lane.key}: ${receive_monitor_lane_status(lane.value)}\n${lane.value['metrics_text']}',
        if (!_audio_enabled) 'Audio: disabled by device capability',
        for (final event in _events)
          '${event['lane']} | ${event['title']}\n${event['summary']}',
      ].join('\n\n');
    });
  }

  String _number(Map<String, dynamic> data, String key,
      {double divisor = 1, int digits = 1, bool allow_negative = false}) {
    final value = data[key];
    return value is num && (value >= 0 || allow_negative)
        ? (value / divisor).toStringAsFixed(digits)
        : '--';
  }

  String _time(dynamic value) {
    if (value is! num || value < 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}.${date.millisecond.toString().padLeft(3, '0')}';
  }

  Widget _metric_row(String label, String current, [String? baseline]) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              flex: 4,
              child:
                  Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(
              flex: 5,
              child: Text(current,
                  style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()]))),
          if (baseline != null)
            Expanded(flex: 4, child: Text(baseline, textAlign: TextAlign.end)),
        ]),
      );

  Widget _lane_card(MapEntry<String, Map<String, dynamic>> lane) {
    final data = lane.value;
    final baseline_supported = data['baseline_supported'] != false;
    final warning = data['gap_alarm'] == true ||
        data['rate_alarm'] == true ||
        data['waiting_alarm'] == true;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lane.key, style: Theme.of(context).textTheme.titleMedium),
                Text(receive_monitor_lane_status(data),
                    style: TextStyle(
                        color: warning ? Colors.deepOrange : Colors.teal)),
                const SizedBox(height: 8),
                Text('Last received (phone time)',
                    style: Theme.of(context).textTheme.labelMedium),
                SelectableText(_time(data['last_received_at_ms']),
                    style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()])),
                _metric_row(
                    'Device sequence',
                    (data['last_seq'] as num? ?? 0) > 0
                        ? _number(data, 'last_seq', digits: 0)
                        : 'Not provided'),
                _metric_row(
                    'Received frame #', _number(data, 'frames', digits: 0)),
                _metric_row('Frame PTS (native packet)',
                    '${_number(data, 'last_pts_ms', digits: 0, allow_negative: true)} ms'),
                _metric_row('Frame size',
                    '${_number(data, 'last_payload_bytes', digits: 0)} B'),
                const Divider(),
                _metric_row('Metric', 'Current',
                    baseline_supported ? 'Baseline' : null),
                _metric_row(
                    'Frame rate',
                    '${_number(data, 'fps')} fps',
                    baseline_supported
                        ? '${_number(data, 'average_fps')} fps'
                        : null),
                _metric_row(
                    'Frame interval',
                    '${_number(data, 'last_gap_ms')} ms',
                    baseline_supported
                        ? '${_number(data, 'average_gap_ms')} ms'
                        : null),
                _metric_row(
                    'Receive rate',
                    '${_number(data, 'rate_bps', divisor: 1000, digits: 2)} KB/s',
                    baseline_supported
                        ? '${_number(data, 'average_bps', divisor: 1000, digits: 2)} KB/s'
                        : null),
                _metric_row('Waiting for next frame',
                    '${_number(data, 'last_frame_age_ms', digits: 0)} ms'),
                _metric_row('Window max interval',
                    '${_number(data, 'max_gap_ms', digits: 0)} ms'),
                _metric_row(
                    'Session average', '${_number(data, 'session_fps')} fps'),
                if (data['baseline_ready'] == true)
                  Text(
                      'Alarm: interval > ${_number(data, 'gap_threshold_ms')} ms; rate <= ${_number(data, 'rate_threshold_bps', divisor: 1000, digits: 2)} KB/s'),
                if (!baseline_supported)
                  const Text(
                      'Baseline alarms are not supported by the native SDK.'),
                if (baseline_supported && data['baseline_ready'] != true)
                  const Text(
                      'No-data timeout: 10s while the baseline is sampling.'),
                Text(
                    'Window: ${_number(data, 'window_frames', digits: 0)} frames / ${_number(data, 'window_ms', digits: 0)} ms, ${_number(data, 'window_bytes', digits: 0)} B'),
                Text(
                    'Total: ${_number(data, 'frames', digits: 0)} frames / ${_number(data, 'payload_bytes', digits: 0)} B'),
              ],
            )));
  }

  Widget _event_card(Map<String, dynamic> event) => ReceiveMonitorEventCard(
        key: PageStorageKey(
            '${event['lane']}_${event['session']}_${event['id']}'),
        title: '${event['lane']} - ${event['title']}',
        subtitle: '${_time(event['recorded_at_ms'])}\n'
            'FPS ${_number(event, 'fps')} / avg ${_number(event, 'average_fps')}; '
            'gap ${event['observed_gap_ms']} ms / limit ${_number(event, 'gap_threshold_ms')} ms; '
            'rate ${_number(event, 'rate_bps', divisor: 1000, digits: 2)} / avg ${_number(event, 'average_bps', divisor: 1000, digits: 2)} KB/s',
        summary: event['summary'] as String? ?? 'No event details',
      );

  void _stop_monitor() {
    _requested = false;
    _timer?.cancel();
    _timer = null;
    _secondary?.stop();
    _primary?.stop();
    _secondary?.destroy();
    _primary?.destroy();
    _secondary = null;
    _primary = null;
    _pipe.abolish();
    if (mounted) setState(() => _status = 'Stopped');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _requested) _stop_monitor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancel_listener?.call();
    _timer?.cancel();
    _secondary?.stop();
    _primary?.stop();
    _secondary?.destroy();
    _primary?.destroy();
    _pipe.abolish();
    _pipe.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('接收稳定性检测')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(widget.deviceId, style: Theme.of(context).textTheme.titleMedium),
          const Text(
              'Shows native receive statistics. Unsupported metrics are unavailable. PTS is the device media clock.'),
          const ReceiveMonitorHelp(),
          const SizedBox(height: 12),
          Text(_status),
          Wrap(spacing: 12, children: [
            FilledButton(
                onPressed: _requested ? _stop_monitor : _start_monitor,
                child: Text(_requested ? 'Stop' : 'Start')),
            OutlinedButton(
                onPressed: () => Clipboard.setData(ClipboardData(
                    text: '${widget.deviceId}\n$_status\n$_report')),
                child: const Text('Copy report')),
          ]),
          const SizedBox(height: 12),
          for (final lane in _lanes) _lane_card(lane),
          if (!_audio_enabled)
            const Text('Audio: disabled by device capability'),
          const SizedBox(height: 16),
          Text('Recent anomaly and recovery events (${_events.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const Text(
              'Expand an event to inspect its metrics and frame context.'),
          if (_events.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No events available')),
          if (_lanes.isNotEmpty &&
              _lanes.every((lane) => lane.value['events_supported'] == false))
            const Text('Event history is not supported by the native SDK.'),
          for (final event in _events) _event_card(event),
        ]),
      );
}

class ReceiveMonitorEventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String summary;

  const ReceiveMonitorEventCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          title: Text(title),
          subtitle: Text(subtitle),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(summary),
            ),
          ],
        ),
      );
}

class ReceiveMonitorHelp extends StatelessWidget {
  const ReceiveMonitorHelp({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          title: const Text('Receive metrics guide'),
          subtitle:
              const Text('Receive time, sequence, PTS and native capabilities'),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Receives one device without decoding or rendering. Cameras and audio are counted separately.\nLast received is the phone wall-clock time when a complete frame reaches the native receive observer, not capture time. Sequence is device-provided; the received frame count is local.\nPTS is the native packet media timestamp, not network latency. Frame rate and payload bytes per second use the current native statistics window; the session average covers this receive session.\nFrame interval is the time between complete frames. Waiting is the age of the latest frame; window max is the largest interval in the current window.\nThe basic native implementation does not provide baseline alarms, inferred sequence loss or event history. Unavailable capabilities are explicitly marked; no normal/abnormal conclusion is inferred from missing data.'),
            ),
          ],
        ),
      );
}
