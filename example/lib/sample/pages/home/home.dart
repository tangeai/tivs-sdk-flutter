part of '../rapid_kit_sample_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.initialTargetDeviceId,
  });

  final String? initialTargetDeviceId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends LifecycleAwareState<HomePage> {
  bool enablePersistentChannel = true;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  final List<Primary> _deviceBasicInfoList = [];
  final Map<String, Thumbnail> _thumbnailsMap = {};
  final Map<String, OnlineStatus> _onlineStatusMap = {};
  final Map<String, BatteryStatus> _batteryStatusMap = {};
  final Map<String, Timezone> _timezoneMap = {};
  bool _initialTargetOpened = false;
  bool _notificationPermissionChecked = false;
  int _loadGeneration = 0;

  @override
  Widget build(BuildContext context) {
    return PlatformUtil.filterPop(
        child: Scaffold(
      key: const ValueKey('rapid-home-page-root'),
      body: _safePaddingTop(_buildPageBody(context)),
    ));
  }

  Widget _safePaddingTop(Widget child) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    _loadData(++_loadGeneration);
    _pushServiceBinding();
    _handleNotificationClick();
    if (enablePersistentChannel) _initializePersistentChannel();
    CallObserver.addIncomingListener(_onIncomingCall);
    Authenticate.addUnauthorizedListener(_onTokenUnauthorized);
  }

  @override
  void start() {
    super.start();

    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (enablePersistentChannel) {
      Future.delayed(const Duration(seconds: 5), () {
        PersistentChannel.connect();
      });
    }
  }

  void _initializePersistentChannel() {
    PersistentChannel.addStateListener(_onPersistentChannelStateChanged);
    PersistentChannel.addMessageListener(_onPersistentChannelMessageReceived);
  }

  /// 用户令牌中途失效，弹窗提示用户重新登录
  void _onTokenUnauthorized() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("登录已失效，请重新登录"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('我知道了'),
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    PushNotificationCoordinator.instance.handleAuthenticationInvalidated();
    await SharedPreferencesUtil.instance
        .setString(SampleConstants.storageKeyLoginToken, "");
    PersistentChannel.disconnect();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _onPersistentChannelStateChanged(PersistentChannelState state) {}

  void _onPersistentChannelMessageReceived(String name, String detail) {}

  void _onIncomingCall(IncomingCall call) {
    if (!mounted) {
      return;
    }
    unawaited(_openIncomingCallPage(call));
  }

  Future<void> _openIncomingCallPage(IncomingCall call) async {
    final primary = await _resolvePrimary(call.deviceId);
    if (!mounted) {
      return;
    }

    _openLivePage(
      primary ?? Primary(deviceId: call.deviceId, deviceName: call.deviceId),
      call: call,
    );
  }

  Future<Primary?> _resolvePrimary(String deviceId) async {
    for (final primary in _deviceBasicInfoList) {
      if (primary.deviceId == deviceId) {
        return primary;
      }
    }

    final response = await SpecService.primary(deviceId);
    if (!response.success) {
      return null;
    }
    return response.data;
  }

  void _openLivePage(Primary primary, {IncomingCall? call}) {
    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => call == null
            ? LivePage(
                deviceId: primary.deviceId ?? '',
                deviceName: primary.deviceName ?? '',
                cameraCount: recognizedCameraCount(primary),
                lan: false,
                deviceAbilities: primary.deviceAbilities,
              )
            : CallLivePage(
                initialIncomingCall: call,
                deviceId: primary.deviceId ?? '',
                deviceName: primary.deviceName ?? '',
                cameraCount: recognizedCameraCount(primary),
                lan: false,
                deviceAbilities: primary.deviceAbilities,
              ),
      ),
    );
  }

  void _handleNotificationClick() async {
    // OpenHarmony uses its existing platform-specific sample binding.
    if (!PlatformUtil.ohos()) {
      return;
    }

    final data = await NotificationChannel.getPendingNotification();

    if (data.isNotEmpty) {
      // You should handle the initial notification data here (launch Notification detail).
      SnackTips.show(context, "Received notification: $data");
    }

    // Then listen to the notification event.
    NotificationChannel.startListening((String data) {
      SnackTips.show(context, "Received notification: $data");
    });
  }

  @override
  void dispose() {
    NotificationChannel.stopListening();

    if (enablePersistentChannel) {
      PersistentChannel.removeStateListener(_onPersistentChannelStateChanged);
      PersistentChannel.removeMessageListener(
          _onPersistentChannelMessageReceived);
      PersistentChannel.disconnect();
    }

    CallObserver.removeIncomingListener(_onIncomingCall);
    Authenticate.removeUnauthorizedListener(_onTokenUnauthorized);

    super.dispose();
  }

  void _pushServiceBinding() async {
    // Notice: we only provide sample on OpenHarmonyOS.
    if (!PlatformUtil.ohos()) {
      return;
    }
    final token = await NotificationChannel.getPushServiceToken();
    final ret =
        await PushNotificationService.associate(token, PushChannel.harmony);
    if (!ret.success) {
      SnackTips.show(context, "Notice: Push service binding failed");
    }
  }

  Future<void> _loadData(int generation) async {
    final localTgrtcDebugging = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigTgrtcDebugging) ??
        SampleConstants.switchOffValue;
    Pipe.debuggingTGRTC(localTgrtcDebugging == SampleConstants.switchOnValue);

    final localStreamDebugging = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigStreamDebugging) ??
        SampleConstants.switchOffValue;
    RapidDiagnostics.enableStreamDebugging(
        localStreamDebugging == SampleConstants.switchOnValue);

    final response =
        await SpecService.primaryByPage(_deviceBasicInfoList.length);
    if (!mounted || generation != _loadGeneration) return;

    if (!response.success) {
      SnackTips.show(context, "请求失败: ${response.code} ${response.message}");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    final newDataList = response.data?.list ?? <Primary>[];
    if (newDataList.isEmpty) {
      hasMoreData = false;
      if (_deviceBasicInfoList.isNotEmpty) {
        SnackTips.show(context, "没有更多数据了！");
      }
    } else {
      final deviceIdList = newDataList
          .map((device) => device.deviceId ?? '')
          .where((deviceId) => deviceId.isNotEmpty)
          .toList();
      await _loadSupplementalDeviceData(deviceIdList, generation);
      if (!mounted || generation != _loadGeneration) return;
      _deviceBasicInfoList.addAll(newDataList);
      hasMoreData = newDataList.length >= 10;
    }

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
    await _requestNotificationPermissionOnce();
    if (!mounted || generation != _loadGeneration) return;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openInitialTargetLivePage());
  }

  Future<void> _loadSupplementalDeviceData(
      List<String> deviceIds, int generation) async {
    if (deviceIds.isEmpty) return;

    final thumbnailFuture = SpecService.thumbnailsOfList(deviceIds);
    final onlineFuture = SpecService.onlineStatusOfList(deviceIds);
    final batteryFuture = SpecService.batteryStatusOfList(deviceIds);
    final timezoneFuture = SpecService.timezoneOfList(deviceIds);

    final thumbnails = await thumbnailFuture;
    final onlineStatuses = await onlineFuture;
    final batteryStatuses = await batteryFuture;
    final timezones = await timezoneFuture;
    if (!mounted || generation != _loadGeneration) return;

    if (thumbnails.success) {
      _thumbnailsMap.addAll(thumbnails.data ?? const {});
    } else {
      _logSupplementalFailure('thumbnail', thumbnails.code, thumbnails.message);
    }
    if (onlineStatuses.success) {
      _onlineStatusMap.addAll(onlineStatuses.data ?? const {});
    } else {
      _logSupplementalFailure(
          'online', onlineStatuses.code, onlineStatuses.message);
    }
    if (batteryStatuses.success) {
      _batteryStatusMap.addAll(batteryStatuses.data ?? const {});
    } else {
      _logSupplementalFailure(
          'battery', batteryStatuses.code, batteryStatuses.message);
    }
    if (timezones.success) {
      _timezoneMap.addAll(timezones.data ?? const {});
    } else {
      _logSupplementalFailure('timezone', timezones.code, timezones.message);
    }
    Logging.i('HomePage',
        '[loadSupplementalDeviceData] completed, generation=$generation, device_count=${deviceIds.length}, timezone_count=${_timezoneMap.length}');
  }

  void _logSupplementalFailure(String name, int? code, String? message) {
    Logging.w('HomePage',
        '[loadSupplementalDeviceData] failed, name=$name, code=${code ?? -1}, message=${message ?? ''}');
  }

  Future<void> _requestNotificationPermissionOnce() async {
    if (_notificationPermissionChecked) return;
    _notificationPermissionChecked = true;
    final enabled = await NotificationChannel.isNotificationEnabled();
    if (!enabled) await NotificationChannel.requestNotificationEnabled();
  }

  Widget _buildPageBody(BuildContext context) {
    double topPadding = Platform.isMacOS ? 16.0 : 0;
    return Container(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, top: topPadding),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              homeTitle(context),
              const SizedBox(height: 10),
              _buildListContainer(),
            ],
          ),
        ));
  }

  Widget _buildListContainer() {
    if (!isLoading) {
      final itemCount = _deviceBasicInfoList.length;
      if (itemCount < 1) {
        return _emptyTips();
      }
    }

    return Expanded(
      child: isLoading
          ? createCenterLoading(size: 20.0)
          : RefreshIndicator(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              color: Colors.white,
              displacement: 50,
              onRefresh: _onPullToRefresh,
              child: _buildList(),
            ),
    );
  }

  Expanded _emptyTips() {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () {
            _onPullToRefresh();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_amber_rounded,
                  size: 50, color: SampleThemeConfigure.colorPrimary),
              SizedBox(height: 10),
              Text(
                '名下无设备',
                style: TextStyle(
                  fontSize: 16,
                  color: SampleThemeConfigure.colorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPullToRefresh() async {
    final generation = ++_loadGeneration;
    _deviceBasicInfoList.clear();
    _thumbnailsMap.clear();
    _onlineStatusMap.clear();
    _batteryStatusMap.clear();
    _timezoneMap.clear();
    setState(() {
      isLoading = true;
      isLoadingMore = false;
      hasMoreData = true;
    });
    return _loadData(generation);
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      cacheExtent: 0,
      itemCount: _deviceBasicInfoList.length + (hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _deviceBasicInfoList.length && hasMoreData) {
          return _buildLoadMore();
        }

        return homeDeviceCard(_deviceBasicInfoList[index], _onlineStatusMap,
            _thumbnailsMap, _batteryStatusMap, _timezoneMap, context, () {
          _onPullToRefresh();
        });
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
    );
  }

  Padding _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 16),
      child: GestureDetector(
        onTap: () async {
          if (isLoadingMore) return;
          setState(() {
            isLoadingMore = true;
          });
          await _loadData(_loadGeneration);
        },
        child: Container(
          decoration: BoxDecoration(
            color: SampleThemeConfigure.colorPrimary,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingMore)
                  const SizedBox(
                    width: 10.0,
                    height: 10.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  ),
                if (isLoadingMore) const SizedBox(width: 8.0),
                const Text(
                  '点击加载更多',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget createLoadMore() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: Center(
        child: createCenterLoading(size: 20.0),
      ),
    );
  }

  Future<void> _openInitialTargetLivePage() async {
    if (_initialTargetOpened || !mounted) {
      return;
    }
    final targetDeviceId = widget.initialTargetDeviceId;
    if (targetDeviceId == null || targetDeviceId.isEmpty) {
      return;
    }
    _initialTargetOpened = true;
    final primary = await _resolvePrimary(targetDeviceId);
    if (!mounted) {
      return;
    }
    if (primary == null) {
      SnackTips.show(context, 'Target device not found: $targetDeviceId');
      return;
    }
    _openLivePage(primary);
  }
}
