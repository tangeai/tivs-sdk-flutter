part of '../rapid_kit_sample_pages.dart';

/// 直播播放页面（支持多个摄像头，即多目设备）
class LivePage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final bool lan;
  final String? deviceAbilities;

  const LivePage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    required this.lan,
    this.deviceAbilities,
  });

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends LifecycleAwareState<LivePage> {
  // ignore: non_constant_identifier_names
  late final String _screen_awake_owner =
      'live:${widget.deviceId}:${identityHashCode(this)}';
  bool _isFullScreen = false;
  bool _active = false;
  final GlobalKey<_LiveStreamWidgetState> _liveStreamKey = GlobalKey();

  void _setActive(bool active) {
    if (_active == active) {
      return;
    }
    setState(() => _active = active);
  }

  void _onFullScreenChanged(bool isFullScreen) {
    setState(() => _isFullScreen = isFullScreen);
  }

  @override
  void start() {
    unawaited(ScreenAwakeChannel.set_enabled(_screen_awake_owner, true));
    _setActive(true);
  }

  @override
  void stop() {
    unawaited(ScreenAwakeChannel.set_enabled(_screen_awake_owner, false));
    _setActive(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    unawaited(ScreenAwakeChannel.set_enabled(
        _screen_awake_owner, state == AppLifecycleState.resumed && _active));
  }

  @override
  void dispose() {
    unawaited(ScreenAwakeChannel.set_enabled(_screen_awake_owner, false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _scaffold(
      widget.deviceName.isEmpty ? widget.deviceId : widget.deviceName,
      context,
      KeyedSubtree(
        key: const ValueKey('rapid-live-page-root'),
        child: LiveStreamWidget(
          key: _liveStreamKey,
          deviceId: widget.deviceId,
          deviceName: widget.deviceName,
          cameraCount: widget.cameraCount,
          lan: widget.lan,
          deviceAbilities: widget.deviceAbilities,
          active: _active,
          onFullScreenChanged: _onFullScreenChanged,
        ),
      ),
      widget.deviceId,
      widget.deviceName,
      showAppBar: !_isFullScreen,
    );
  }
}
