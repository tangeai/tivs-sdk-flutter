part of 'rapid_kit_sample_widget.dart';

abstract class MediaDumpSender {
  bool startDump();

  bool stopDump();
}

class MediaDumpController {
  MediaDumpController({
    required this.context,
    required this.mounted,
    required this.players,
    required this.chatSessions,
    required this.log,
    required this.onStateChanged,
  });

  final BuildContext Function() context;
  final bool Function() mounted;
  final List<Player> Function() players;
  final List<MediaDumpSender> Function() chatSessions;
  final ValueChanged<String> log;
  final VoidCallback onStateChanged;

  bool _dumping = false;
  bool _uploading = false;

  bool get dumping => _dumping;
  bool get uploading => _uploading;

  Widget buildActionButton({
    required bool canStart,
    required String unavailableMessage,
  }) {
    final enabled = _uploading || _dumping || canStart;
    return buildDumpPillButton(
      dumping: _dumping,
      uploading: _uploading,
      enabled: enabled,
      onTap: () {
        handleTap(canStart: canStart, unavailableMessage: unavailableMessage);
      },
    );
  }

  Future<void> handleTap({
    required bool canStart,
    required String unavailableMessage,
  }) async {
    if (_uploading) {
      return;
    }

    final targetPlayers = players();
    final targetChatSessions = chatSessions();
    if (targetPlayers.isEmpty && targetChatSessions.isEmpty) {
      _showSnack('抓流不可用');
      return;
    }

    if (_dumping) {
      log('dump_stop_requested');
      final stopped = _stopDump(targetPlayers, targetChatSessions);
      if (!stopped) {
        log('dump_stop_failed');
        _showSnack('停止抓流失败');
        return;
      }

      if (!mounted()) {
        return;
      }

      _updateState(dumping: false, uploading: true);
      await _uploadDumpLogs();
      return;
    }

    if (!canStart) {
      _showSnack(unavailableMessage);
      return;
    }

    log('dump_start_requested');
    final started = _startDump(targetPlayers, targetChatSessions);
    if (!mounted()) {
      return;
    }
    if (!started) {
      log('dump_start_failed');
      _showSnack('开始抓流失败');
      return;
    }

    _updateState(dumping: true);
    log('dump_start_applied');
  }

  void forceStopIfNeeded(String reason, {bool notifyStateChanged = true}) {
    if (_dumping) {
      log('dump_stop_forced, reason=$reason');
      _stopDump(players(), chatSessions());
    }
    _updateState(
      dumping: false,
      uploading: false,
      notifyStateChanged: notifyStateChanged,
    );
  }

  Future<void> _uploadDumpLogs() async {
    log('dump_upload_requested');
    final resp = await DumpUploadFeedback.uploadLogs(context());
    if (!mounted()) {
      return;
    }

    _updateState(uploading: false);
    if (resp.success) {
      log('dump_upload_succeeded, logId=${resp.data}');
      return;
    }

    log('dump_upload_failed, code=${resp.code}, message=${resp.message}');
  }

  bool _startDump(
    List<Player> targetPlayers,
    List<MediaDumpSender> targetChatSessions,
  ) {
    final startedPlayers = <Player>[];
    for (final player in targetPlayers) {
      if (!player.startDump()) {
        for (final startedPlayer in startedPlayers.reversed) {
          startedPlayer.stopDump();
        }
        return false;
      }
      startedPlayers.add(player);
    }

    final startedChatSessions = <MediaDumpSender>[];
    for (final chatSession in targetChatSessions) {
      if (!chatSession.startDump()) {
        for (final startedChatSession in startedChatSessions.reversed) {
          startedChatSession.stopDump();
        }
        for (final startedPlayer in startedPlayers.reversed) {
          startedPlayer.stopDump();
        }
        return false;
      }
      startedChatSessions.add(chatSession);
    }
    return startedPlayers.isNotEmpty || startedChatSessions.isNotEmpty;
  }

  bool _stopDump(
    List<Player> targetPlayers,
    List<MediaDumpSender> targetChatSessions,
  ) {
    if (targetPlayers.isEmpty && targetChatSessions.isEmpty) {
      return false;
    }

    var success = true;
    for (final player in targetPlayers) {
      success = player.stopDump() && success;
    }
    for (final chatSession in targetChatSessions) {
      success = chatSession.stopDump() && success;
    }
    return success;
  }

  void _showSnack(String message) {
    if (!mounted()) {
      return;
    }
    SnackTips.show(context(), message);
  }

  void _updateState({
    bool? dumping,
    bool? uploading,
    bool notifyStateChanged = true,
  }) {
    _dumping = dumping ?? _dumping;
    _uploading = uploading ?? _uploading;
    if (notifyStateChanged && mounted()) {
      onStateChanged();
    }
  }
}

Widget buildDumpPillButton({
  required bool dumping,
  required bool uploading,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return _DumpPillButton(
    key: const ValueKey('rapid-live-dump-action'),
    dumping: dumping,
    uploading: uploading,
    enabled: enabled,
    onTap: onTap,
  );
}

class _DumpPillButton extends StatefulWidget {
  final bool dumping;
  final bool uploading;
  final bool enabled;
  final VoidCallback onTap;

  const _DumpPillButton({
    super.key,
    required this.dumping,
    required this.uploading,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DumpPillButton> createState() => _DumpPillButtonState();
}

class _DumpPillButtonState extends State<_DumpPillButton>
    with SingleTickerProviderStateMixin {
  static const Color _activeColor = Color(0xFFE5484D);

  late final AnimationController _blinkController;
  late final Animation<double> _blinkOpacity;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _blinkOpacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _syncBlinking();
  }

  @override
  void didUpdateWidget(covariant _DumpPillButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBlinking();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _syncBlinking() {
    if (widget.dumping && !widget.uploading) {
      _blinkController.repeat(reverse: true);
      return;
    }

    _blinkController.stop();
    _blinkController.value = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.dumping && !widget.uploading;
    final label = widget.uploading
        ? '上传中...'
        : active
        ? '停止抓流'
        : '采集原始视频流与日志';
    final backgroundColor = active
        ? Colors.white.withOpacity(0.96)
        : SampleThemeConfigure.colorPrimary;
    final textColor = active ? _activeColor : Colors.white;

    return IgnorePointer(
      ignoring: !widget.enabled || widget.uploading,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.enabled ? 1 : 0.52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: active
                    ? Border.all(color: _activeColor.withOpacity(0.9), width: 1)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? _activeColor.withOpacity(0.16)
                        : Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.uploading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  else
                    _buildIndicator(active),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      label,
                      key: ValueKey<String>(label),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(bool active) {
    if (!active) {
      return const Icon(
        Icons.fiber_manual_record_rounded,
        size: 12,
        color: Colors.white,
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _activeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _activeColor.withOpacity(0.24),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _blinkOpacity,
        child: const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 4, height: 4),
          ),
        ),
      ),
    );
  }
}
