part of '../../rapid_kit_sample_pages.dart';

class LocalReplayFrameHoldController extends ChangeNotifier {
  bool _holding = true;
  bool _disposed = false;

  bool get holding => _holding;

  /// Covers the external texture synchronously while a new frame is pending.
  /// Flutter cannot reliably rasterize platform textures into an image on OHOS.
  void hold() {
    if (_disposed || _holding) return;
    _holding = true;
    notifyListeners();
  }

  void release() {
    if (_disposed || !_holding) return;
    _holding = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class LocalReplayHeldTexture extends StatelessWidget {
  final Widget texture;
  final LocalReplayFrameHoldController controller;

  const LocalReplayHeldTexture({
    super.key,
    required this.texture,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            child!,
            if (controller.holding) const ColoredBox(color: Colors.black),
          ],
        );
      },
      child: texture,
    );
  }
}

class LocalReplayStage extends StatelessWidget {
  final int cameraCount;
  final double availableHeight;
  final double width;
  final bool showConnectionError;
  final bool showBuffering;
  final String? bufferingMessage;
  final bool bufferingTimedOut;
  final List<String?> playerStatusMessages;
  final bool paused;
  final bool pipeEstablished;
  final String? connectionState;
  final VoidCallback onRetryConnection;
  final Widget stats;
  final Widget? topRightOverlay;
  final Widget timelinePanel;
  final Widget controlsPanel;
  final Widget dateButton;
  final Widget texture0;
  final Widget? texture1;
  final Widget? texture2;
  final Widget? texture3;
  final LocalReplayFrameHoldController holdController0;
  final LocalReplayFrameHoldController? holdController1;
  final LocalReplayFrameHoldController? holdController2;
  final LocalReplayFrameHoldController? holdController3;

  const LocalReplayStage({
    super.key,
    required this.cameraCount,
    required this.availableHeight,
    required this.width,
    required this.showConnectionError,
    required this.showBuffering,
    this.bufferingMessage,
    this.bufferingTimedOut = false,
    this.playerStatusMessages = const [],
    required this.paused,
    required this.pipeEstablished,
    required this.connectionState,
    required this.onRetryConnection,
    required this.stats,
    this.topRightOverlay,
    required this.timelinePanel,
    required this.controlsPanel,
    required this.dateButton,
    required this.texture0,
    this.texture1,
    this.texture2,
    this.texture3,
    required this.holdController0,
    this.holdController1,
    this.holdController2,
    this.holdController3,
  });

  @override
  Widget build(BuildContext context) {
    const controlsHeight = 64.0;
    // Include the date/zoom header and room to drag or select a recording.
    const minimumTimelineHeight = 240.0;
    final naturalVideoHeight =
        cameraCount == 4 ? width * 9 / 16 : width * 9 / 16 * cameraCount;
    final maximumVideoHeight =
        math.max(0.0, availableHeight - controlsHeight - minimumTimelineHeight);
    final videoHeight = math.min(naturalVideoHeight, maximumVideoHeight);

    return Column(
      children: [
        SizedBox(
          key: const ValueKey('rapid-local-replay-video-region'),
          width: width,
          height: videoHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPlayers(videoHeight),
              if (showConnectionError)
                LocalReplayConnectionErrorOverlay(
                  width: width,
                  height: videoHeight,
                  message: connectionState != null
                      ? 'Device connect failed\n$connectionState'
                      : 'Device connect failed',
                  onRetry: onRetryConnection,
                ),
              if (!showConnectionError && showBuffering)
                LocalReplayBufferingOverlay(
                  width: width,
                  height: videoHeight,
                  message: bufferingMessage,
                  timedOut: bufferingTimedOut,
                ),
              if (!showConnectionError && paused)
                LocalReplayPausedOverlay(
                  width: width,
                  height: videoHeight,
                  message: 'Paused',
                ),
              _ReplayStatsOverlay(
                stats: stats,
                width: width,
                height: videoHeight,
              ),
              if (!showConnectionError && topRightOverlay != null)
                Positioned(
                  top: 58,
                  right: 12,
                  child: topRightOverlay!,
                ),
            ],
          ),
        ),
        Expanded(
          child: ClipRect(
            key: const ValueKey('rapid-local-replay-timeline-region'),
            child: pipeEstablished
                ? timelinePanel
                : const ColoredBox(color: Color(0xFFF4F7F7)),
          ),
        ),
        if (!showConnectionError) controlsPanel,
      ],
    );
  }

  Widget _buildPlayers(double videoHeight) {
    if (cameraCount == 4) {
      return buildFourCameraGrid([
        for (int index = 0; index < 4; index++)
          LayoutBuilder(builder: (context, constraints) {
            final textures = [texture0, texture1, texture2, texture3];
            final holds = [
              holdController0,
              holdController1,
              holdController2,
              holdController3
            ];
            final texture = textures[index];
            final hold = holds[index];
            if (texture == null || hold == null) {
              return const ColoredBox(color: Colors.black);
            }
            return _buildPlayerWidget(texture, hold, constraints.maxWidth,
                constraints.maxHeight, index);
          }),
      ]);
    }

    final actualPlayerHeight = videoHeight / cameraCount;
    return Column(
      children: [
        _buildPlayerWidget(
            texture0, holdController0, width, actualPlayerHeight, 0),
        if (cameraCount > 1 && texture1 != null && holdController1 != null)
          _buildPlayerWidget(
              texture1!, holdController1!, width, actualPlayerHeight, 1),
        if (cameraCount > 2 && texture2 != null && holdController2 != null)
          _buildPlayerWidget(
              texture2!, holdController2!, width, actualPlayerHeight, 2),
      ],
    );
  }

  Widget _buildPlayerWidget(
      Widget texture,
      LocalReplayFrameHoldController holdController,
      double width,
      double height,
      int index) {
    final message = index < playerStatusMessages.length
        ? playerStatusMessages[index]
        : null;
    return Container(
      width: width,
      height: height,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LocalReplayHeldTexture(
            texture: texture,
            controller: holdController,
          ),
          if (!showConnectionError && !paused && message != null)
            LocalReplayBufferingOverlay(
              key: ValueKey('local-replay-lane-status-$index'),
              width: width,
              height: height,
              message: message,
              timedOut: bufferingTimedOut,
            ),
        ],
      ),
    );
  }
}

class _ReplayStatsOverlay extends StatefulWidget {
  final Widget stats;
  final double width;
  final double height;

  const _ReplayStatsOverlay({
    required this.stats,
    required this.width,
    required this.height,
  });

  @override
  State<_ReplayStatsOverlay> createState() => _ReplayStatsOverlayState();
}

class _ReplayStatsOverlayState extends State<_ReplayStatsOverlay> {
  static const double _inset = 10;
  static const double _collapsedSize = 36;
  static const double _expandedHeight = 40;

  Offset? _position;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.width < 100 || widget.height < 60) {
      return const SizedBox.shrink();
    }

    final overlayWidth =
        _expanded ? math.min(360.0, widget.width - _inset * 2) : _collapsedSize;
    final overlayHeight = _expanded ? _expandedHeight : _collapsedSize;
    final maxLeft = widget.width - overlayWidth - _inset;
    final maxTop = widget.height - overlayHeight - _inset;
    final current = _position ?? Offset(_inset, maxTop);
    final position = Offset(
      current.dx.clamp(_inset, maxLeft).toDouble(),
      current.dy.clamp(_inset, maxTop).toDouble(),
    );

    return Positioned(
      key: const ValueKey('rapid-local-replay-stats-position'),
      left: position.dx,
      top: position.dy,
      width: overlayWidth,
      height: overlayHeight,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final latest = _position ?? position;
            _position = Offset(
              (latest.dx + details.delta.dx).clamp(_inset, maxLeft).toDouble(),
              (latest.dy + details.delta.dy).clamp(_inset, maxTop).toDouble(),
            );
          });
        },
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          elevation: 2,
          child: _expanded
              ? Row(
                  children: [
                    const Icon(Icons.drag_indicator,
                        size: 18, color: Colors.black54),
                    Expanded(child: SizedBox(height: 28, child: widget.stats)),
                    IconButton(
                      key: const ValueKey('rapid-local-replay-stats-collapse'),
                      tooltip: 'Collapse logs',
                      onPressed: () => setState(() => _expanded = false),
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 36, height: 36),
                    ),
                  ],
                )
              : IconButton(
                  key: const ValueKey('rapid-local-replay-stats-expand'),
                  tooltip: 'Show logs',
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(Icons.article_outlined, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: _collapsedSize,
                    height: _collapsedSize,
                  ),
                ),
        ),
      ),
    );
  }
}
