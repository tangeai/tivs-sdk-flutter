part of '../../rapid_kit_sample_pages.dart';

class LiveRecordUiHelpers {
  static int elapsedSecondsFromRecordDurationMs(int durationMs) {
    if (durationMs <= 0) {
      return 0;
    }
    return (durationMs / Duration.millisecondsPerSecond).ceil();
  }

  static String formatElapsedSeconds(int elapsedSeconds) {
    final safeSeconds = math.max(0, elapsedSeconds);
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

Widget buildLiveRecordElapsedBadge({
  required bool videoCapturing,
  required int elapsedSeconds,
}) {
  if (!videoCapturing) {
    return const SizedBox.shrink();
  }

  return Semantics(
    key: const ValueKey('rapid-live-record-duration'),
    label: 'rapid-live-record-duration',
    value: 'elapsed_seconds=$elapsedSeconds',
    child: Text(
      LiveRecordUiHelpers.formatElapsedSeconds(elapsedSeconds),
      style: const TextStyle(
        color: SampleThemeConfigure.colorActive,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _buildRecordButton(
  bool videoCapturing,
  int recordElapsedSeconds,
  VoidCallback onPressed,
) {
  return SizedBox(
    width: 88,
    height: 48,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('rapid-live-record-action'),
          icon: Icon(Icons.emergency_recording_rounded,
              size: 25,
              color: videoCapturing
                  ? SampleThemeConfigure.colorActive
                  : SampleThemeConfigure.colorTextPrimary),
          onPressed: onPressed,
        ),
        SizedBox(
          width: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: buildLiveRecordElapsedBadge(
              videoCapturing: videoCapturing,
              elapsedSeconds: recordElapsedSeconds,
            ),
          ),
        ),
      ],
    ),
  );
}

IconButton _buildShotButton(VoidCallback onPressed) {
  return IconButton(
    key: const ValueKey('rapid-live-capture-action'),
    icon: const Icon(Icons.camera_alt,
        size: 25, color: SampleThemeConfigure.colorTextPrimary),
    onPressed: onPressed,
  );
}

IconButton _buildFullScreenButton(bool isFullScreen, VoidCallback onPressed) {
  return IconButton(
    key: const ValueKey('rapid-live-fullscreen-enter-action'),
    icon: Icon(
        isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
        size: 25,
        color: isFullScreen
            ? SampleThemeConfigure.colorActive
            : SampleThemeConfigure.colorTextPrimary),
    onPressed: onPressed,
  );
}

IconButton _buildVolumeButton(bool audioMuted, VoidCallback onPressed) {
  return IconButton(
    icon: Icon(audioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        size: 25,
        color: audioMuted
            ? SampleThemeConfigure.colorTextPrimary
            : SampleThemeConfigure.colorTextPrimary),
    onPressed: onPressed,
  );
}

IconButton _buildLocalReplayButton(VoidCallback onPressed) {
  return IconButton(
    key: const ValueKey('rapid-live-local-replay-action'),
    icon: const Icon(Icons.sd_card,
        size: 25, color: SampleThemeConfigure.colorTextPrimary),
    onPressed: onPressed,
  );
}

Widget _buildOperationOfFullScreen(
  bool audioMuted,
  bool videoCapturing,
  int recordElapsedSeconds,
  VoidCallback onToggleFullScreen,
  VoidCallback onVolumeTap,
  VoidCallback onCapture,
  VoidCallback onRecordTap,
) {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('rapid-live-fullscreen-exit-action'),
            icon: const Icon(Icons.fullscreen_exit_rounded,
                size: 25, color: Colors.red),
            onPressed: onToggleFullScreen,
          ),
          IconButton(
            icon: Icon(
              audioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: 25,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
            onPressed: onVolumeTap,
          ),
          IconButton(
            key: const ValueKey('rapid-live-capture-action-fullscreen'),
            icon: const Icon(Icons.camera_alt,
                size: 25, color: SampleThemeConfigure.colorTextPrimary),
            onPressed: onCapture,
          ),
          KeyedSubtree(
            key: const ValueKey('rapid-live-record-action-fullscreen'),
            child: _buildRecordButton(
              videoCapturing,
              recordElapsedSeconds,
              onRecordTap,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQualitySwitch(
    bool isHighQuality, Function(bool) onSelectionChanged) {
  return Semantics(
    key: const ValueKey('rapid-live-quality-switch'),
    label: 'rapid-live-quality-switch',
    value: isHighQuality ? 'quality=high' : 'quality=standard',
    child: SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: false,
          label: Text(
            '标清',
            key: ValueKey('rapid-live-quality-standard-action'),
          ),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text(
            '高清',
            key: ValueKey('rapid-live-quality-high-action'),
          ),
        ),
      ],
      selected: {isHighQuality},
      onSelectionChanged: (Set<bool> selection) {
        onSelectionChanged(selection.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: SampleThemeConfigure.colorTextPrimary,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: SampleThemeConfigure.colorPrimary,
        side: BorderSide.none,
        padding: const EdgeInsets.all(6),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        minimumSize: const Size(0, 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

Widget buildLivePlayersLayout(
  List<Widget> playerWidgets, {
  required bool isFullScreen,
  required Size size,
}) {
  final count = playerWidgets.length;
  final isLandscape = size.width > size.height;
  final useLandscapeLayout = isFullScreen && isLandscape && count > 1;
  final mode = count == 1
      ? (isFullScreen ? 'single_fullscreen' : 'single_inline')
      : useLandscapeLayout
          ? (count == 2 ? 'landscape_split' : 'landscape_focus')
          : 'vertical_stack';

  Widget child;
  if (count == 1) {
    child = _buildSingleLivePlayer(playerWidgets.first, isFullScreen, size);
  } else if (useLandscapeLayout && count == 2) {
    child = _buildLandscapeSplitPlayers(playerWidgets);
  } else if (useLandscapeLayout) {
    child = _buildLandscapeFocusPlayers(playerWidgets);
  } else {
    child = buildPlayersColumn(playerWidgets);
  }

  return Semantics(
    key: const ValueKey('rapid-live-player-layout'),
    label: 'rapid-live-player-layout',
    value:
        'mode=$mode,count=$count,fullscreen=$isFullScreen,landscape=$isLandscape,width=${size.width.toStringAsFixed(1)},height=${size.height.toStringAsFixed(1)}',
    child: child,
  );
}

Widget _buildSingleLivePlayer(
  Widget player,
  bool isFullScreen,
  Size size,
) {
  if (isFullScreen) {
    return SizedBox.expand(child: player);
  }
  final side = math.max(0.0, math.min(size.width, size.height));
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: side,
      height: side,
      child: player,
    ),
  );
}

Widget _buildLandscapeSplitPlayers(List<Widget> playerWidgets) {
  return Row(
    children: [
      Expanded(child: _buildLivePlayerSlot(playerWidgets[0])),
      const SizedBox(width: 8),
      Expanded(child: _buildLivePlayerSlot(playerWidgets[1])),
    ],
  );
}

Widget _buildLandscapeFocusPlayers(List<Widget> playerWidgets) {
  final sidePlayers = playerWidgets.skip(1).take(2).toList();
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: _buildLivePlayerSlot(playerWidgets.first),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          children: [
            for (int i = 0; i < sidePlayers.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Expanded(child: _buildLivePlayerSlot(sidePlayers[i])),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget _buildLivePlayerSlot(Widget player) {
  return ClipRect(
    child: ColoredBox(
      color: SampleThemeConfigure.colorVideoBackground,
      child: SizedBox.expand(child: player),
    ),
  );
}

Widget buildPlayersColumn(List<Widget> playerWidgets) {
  List<Widget> children = [];

  for (int i = 0; i < playerWidgets.length; i++) {
    if (i > 0) children.add(const SizedBox(height: 8));
    children.add(
      AspectRatio(
        aspectRatio: 16 / 9,
        child: playerWidgets[i],
      ),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final totalAspectHeight =
          constraints.maxWidth * 9 / 16 * playerWidgets.length +
              math.max(0, playerWidgets.length - 1) * 8;
      if (totalAspectHeight <= constraints.maxHeight) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        );
      }
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: children,
      );
    },
  );
}

Widget _buildMiddleControls(
  bool audioMuted,
  bool videoCapturing,
  int recordElapsedSeconds,
  bool isFullScreen,
  VoidCallback onVolumeTap,
  VoidCallback onCapture,
  VoidCallback onRecordTap,
  VoidCallback onLocalReplayTap,
  VoidCallback onToggleFullScreen,
) {
  return Container(
    height: 50,
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _buildVolumeButton(audioMuted, onVolumeTap),
        _buildShotButton(onCapture),
        _buildRecordButton(videoCapturing, recordElapsedSeconds, onRecordTap),
        _buildLocalReplayButton(onLocalReplayTap),
        _buildFullScreenButton(isFullScreen, onToggleFullScreen),
      ],
    ),
  );
}

Widget buildBottomOverlayTools({
  required Widget left,
  required Widget right,
}) {
  return buildBottomOverlayToolBar(
    qualitySwitch: left,
    intercomButton: right,
  );
}

const double kBottomOverlayToolWidth = 160;
const double kBottomOverlayIntercomPillHeight = 44;
const double kBottomOverlayToolStackHeight = 96;

Widget buildBottomOverlayToolBar({
  required Widget qualitySwitch,
  required Widget intercomButton,
}) {
  return SizedBox(
    height: kBottomOverlayToolStackHeight,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: kBottomOverlayToolWidth,
          child: Align(alignment: Alignment.bottomLeft, child: qualitySwitch),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: IntrinsicWidth(child: intercomButton),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildIntercomPillButton({
  required bool chatStarted,
  required bool usePushToTalk,
  required Future<void> Function() onTapToggle,
  required Future<bool> Function() onPressStart,
  required Future<void> Function() onPressEnd,
}) {
  return _IntercomPillButton(
    chatStarted: chatStarted,
    usePushToTalk: usePushToTalk,
    onTapToggle: onTapToggle,
    onPressStart: onPressStart,
    onPressEnd: onPressEnd,
  );
}

class _IntercomPillButton extends StatefulWidget {
  final bool chatStarted;
  final bool usePushToTalk;
  final Future<void> Function() onTapToggle;
  final Future<bool> Function() onPressStart;
  final Future<void> Function() onPressEnd;

  const _IntercomPillButton({
    required this.chatStarted,
    required this.usePushToTalk,
    required this.onTapToggle,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  State<_IntercomPillButton> createState() => _IntercomPillButtonState();
}

class _IntercomPillButtonState extends State<_IntercomPillButton> {
  bool _pressing = false;

  bool get _active => _pressing || widget.chatStarted;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _IntercomPillButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRipple();
  }

  void _syncRipple() {
    return;
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _labelText() {
    if (widget.usePushToTalk) {
      return _active ? '松开停止对讲' : '按住开始对讲';
    }
    return widget.chatStarted ? '结束对讲' : '开始对讲';
  }

  Future<void> _handlePressStart() async {
    if (!widget.usePushToTalk) return;
    if (_pressing) return;

    setState(() => _pressing = true);
    _syncRipple();

    final ok = await widget.onPressStart();
    if (!ok && mounted) {
      setState(() => _pressing = false);
      _syncRipple();
    }
  }

  Future<void> _handlePressEnd() async {
    if (!widget.usePushToTalk) return;
    if (!_pressing) return;
    await widget.onPressEnd();
    if (!mounted) return;
    setState(() => _pressing = false);
    _syncRipple();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        _active ? Colors.red : SampleThemeConfigure.colorPrimary;

    final label = Flexible(
      child: Text(
        _labelText(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    final pill = AnimatedScale(
      scale: _pressing ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        height: kBottomOverlayIntercomPillHeight,
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(kBottomOverlayIntercomPillHeight / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            label,
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.usePushToTalk ? null : () => widget.onTapToggle(),
      onTapDown: widget.usePushToTalk ? (_) => _handlePressStart() : null,
      onTapUp: widget.usePushToTalk ? (_) => _handlePressEnd() : null,
      onTapCancel: widget.usePushToTalk ? () => _handlePressEnd() : null,
      child: pill,
    );
  }
}
