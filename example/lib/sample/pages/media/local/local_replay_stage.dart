part of '../../rapid_kit_sample_pages.dart';

class LocalReplayStage extends StatelessWidget {
  final int cameraCount;
  final double availableHeight;
  final double width;
  final bool showConnectionError;
  final bool showBuffering;
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

  const LocalReplayStage({
    super.key,
    required this.cameraCount,
    required this.availableHeight,
    required this.width,
    required this.showConnectionError,
    required this.showBuffering,
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
  });

  @override
  Widget build(BuildContext context) {
    final playerHeight = width * 9 / 16;
    final totalNeededHeight = playerHeight * cameraCount;
    final actualPlayerHeight = totalNeededHeight <= availableHeight
        ? playerHeight
        : availableHeight / cameraCount;

    return Stack(
      children: [
        SizedBox(
          height: availableHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerWidget(texture0, width, actualPlayerHeight),
              if (cameraCount > 1 && texture1 != null)
                _buildPlayerWidget(texture1!, width, actualPlayerHeight),
              if (cameraCount > 2 && texture2 != null)
                _buildPlayerWidget(texture2!, width, actualPlayerHeight),
            ],
          ),
        ),
        if (showConnectionError)
          LocalReplayConnectionErrorOverlay(
            width: width,
            height: availableHeight,
            message: connectionState != null
                ? 'Device connect failed\n$connectionState'
                : 'Device connect failed',
            onRetry: onRetryConnection,
          ),
        if (!showConnectionError && showBuffering)
          LocalReplayBufferingOverlay(width: width, height: availableHeight),
        if (!showConnectionError && paused)
          LocalReplayPausedOverlay(
            width: width,
            height: availableHeight,
            message: 'Paused',
          ),
        if (!showConnectionError && pipeEstablished) timelinePanel,
        if (!showConnectionError) controlsPanel,
        if (!showConnectionError && pipeEstablished) dateButton,
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: stats,
        ),
        if (!showConnectionError && topRightOverlay != null)
          Positioned(
            top: 64,
            right: 16,
            child: topRightOverlay!,
          ),
      ],
    );
  }

  Widget _buildPlayerWidget(Widget texture, double width, double height) {
    return Container(
      width: width,
      height: height,
      color: SampleThemeConfigure.colorVideoBackground,
      child: texture,
    );
  }
}
