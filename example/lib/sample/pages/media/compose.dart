part of '../rapid_kit_sample_pages.dart';

/// 聚合播放页面，包含直播和卡录像两个 TAB
class ComposePage extends StatefulWidget {
  static const String tag = 'ComposePage';

  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final bool lan;
  final String? deviceAbilities;

  const ComposePage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    required this.lan,
    this.deviceAbilities,
  });

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends LifecycleAwareState<ComposePage>
    with SingleTickerProviderStateMixin {
  // 自动化测试模式：随机时间切换 TAB
  static const bool _autoTestMode = false;

  late TabController _tabController;
  final GlobalKey<_LiveStreamWidgetState> _liveStreamKey = GlobalKey();
  final GlobalKey<_LocalReplayWidgetState> _localReplayKey = GlobalKey();
  late final LocalReplayPlaybackController _localReplayController;

  bool _pageActive = false;
  int _currentIndex = 0;
  late AutoActionScheduler _autoScheduler;

  static const int _tabIndexLive = 0;
  static const int _tabIndexLocalReplay = 1;

  String _tabName(int index) {
    switch (index) {
      case _tabIndexLive:
        return 'live';
      case _tabIndexLocalReplay:
        return 'local_replay';
      default:
        return 'unknown($index)';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _localReplayController = LocalReplayPlaybackController();

    _autoScheduler = AutoActionScheduler(
      onAction: () {
        final targetIndex = _currentIndex == 0 ? 1 : 0;
        _tabController.animateTo(targetIndex);
      },
    );
  }

  @override
  void dispose() {
    _autoScheduler.stop();
    _localReplayController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  bool _isTabActive(int tabIndex) {
    return _pageActive && _currentIndex == tabIndex;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    final newIndex = _tabController.index;
    if (newIndex == _currentIndex) {
      return;
    }

    final oldIndex = _currentIndex;
    Logging.i(ComposePage.tag,
        '[tabChanged] ${_tabName(oldIndex)} -> ${_tabName(newIndex)}');
    _currentIndex = newIndex;
    _syncLocalReplayPlayback();
    setState(() {});
  }

  void _syncLocalReplayPlayback() {
    if (_isTabActive(_tabIndexLocalReplay)) {
      _localReplayController.start();
    } else {
      _localReplayController.stop();
    }
  }

  @override
  void start() {
    if (_pageActive) {
      return;
    }
    _pageActive = true;
    _syncLocalReplayPlayback();
    setState(() {});
    if (_autoTestMode) {
      _autoScheduler.start();
    }
  }

  @override
  void stop() {
    _autoScheduler.stop();
    if (!_pageActive) {
      return;
    }
    _pageActive = false;
    _syncLocalReplayPlayback();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("聚合播放",
                style: TextStyle(
                    color: SampleThemeConfigure.colorPrimary, fontSize: 16)),
            if (_autoTestMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Text(
                  "自动化测试中...",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
        backgroundColor: SampleThemeConfigure.colorBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: SampleThemeConfigure.colorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: SampleThemeConfigure.colorPrimary,
                backgroundColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(50, 28),
                side: const BorderSide(
                    color: SampleThemeConfigure.colorPrimary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => InstructOverlay.show(
                  context, widget.deviceId, widget.deviceName),
              child: const Text("指令",
                  style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SampleThemeConfigure.colorPrimary,
          labelColor: SampleThemeConfigure.colorPrimary,
          unselectedLabelColor: SampleThemeConfigure.colorTextHint,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: SampleThemeConfigure.colorPrimary.withOpacity(0.1),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: "直播"),
            Tab(text: "卡录像"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LiveStreamWidget(
            key: _liveStreamKey,
            deviceId: widget.deviceId,
            deviceName: widget.deviceName,
            cameraCount: widget.cameraCount,
            lan: widget.lan,
            deviceAbilities: widget.deviceAbilities,
            active: _isTabActive(_tabIndexLive),
          ),
          LocalReplayWidget(
            key: _localReplayKey,
            deviceId: widget.deviceId,
            deviceName: widget.deviceName,
            cameraCount: widget.cameraCount,
            deviceAbilities: widget.deviceAbilities,
            playbackController: _localReplayController,
          ),
        ],
      ),
    );
  }
}
