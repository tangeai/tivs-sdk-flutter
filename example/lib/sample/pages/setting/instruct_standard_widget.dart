part of '../rapid_kit_sample_pages.dart';

class InstructStandardWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final Function(bool connected, bool failed)? onConnectionStateChanged;

  const InstructStandardWidget(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      this.onConnectionStateChanged});

  @override
  State<InstructStandardWidget> createState() => _InstructStandardWidgetState();
}

class _InstructStandardWidgetState extends State<InstructStandardWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  static const String _tag = "_InstructStandardWidget_";

  static const Set<String> _conditionalSections = {
    "\u4E91\u53F0",
    "\u9884\u7F6E\u4F4D",
    "\u89C6\u9891\u6E05\u6670\u5EA6",
    "\u5B58\u50A8\u5361",
    "\u53D8\u7126",
    "\u7535\u6C60\u72B6\u6001",
    "PIR",
    "\u72B6\u6001\u706F-LED",
    "\u7535\u6E90\u9891\u7387",
    "Wi-Fi",
    "\u7F51\u7EDC\u4E0E\u4FE1\u53F7",
    "\u7F51\u7EDC\u914D\u7F6E",
    "\u753B\u9762",
    "\u767D\u5149\u706F",
    "\u591C\u89C6",
    "\u5F55\u50CF",
    "\u5F00\u5173",
    "\u955C\u5934\u5173\u95ED\u8BA1\u5212",
    "\u5587\u53ED",
    "\u9EA6\u514B\u98CE",
    "\u4E8B\u4EF6\u4FA6\u6D4B",
    "AI\u529F\u80FD\u5F00\u5173",
    "\u79FB\u52A8\u8FFD\u8E2A",
    "\u79FB\u52A8\u4FA6\u6D4B",
    "\u5BA0\u7269\u5582\u98DF",
    "\u8B66\u6212\u8BED\u97F3",
    "\u7535\u6E90\u7B56\u7565",
    "\u6269\u5C55\u6307\u4EE4\u6D4B\u8BD5",
  };

  static const Set<String> _conditionalOptions = {
    "\u4F11\u7720\u6307\u4EE4-\u67E5\u8BE2\u6700\u5927\u5524\u9192\u65F6\u957F",
    "\u5C4F\u5E55\u663E\u793A\u6307\u4EE4-\u67E5\u8BE2\u663E\u793A\u65F6\u957F",
    "OSD\u6307\u4EE4-\u67E5\u8BE2\u901A\u90530",
    "\u79FB\u52A8\u4FA6\u6D4B\u533A\u57DF\u6307\u4EE4-\u67E5\u8BE2\u901A\u90530",
    "\u5DE1\u822A\u6307\u4EE4-\u67E5\u8BE2\u80FD\u529B\u548C\u8F68\u8FF9",
    "\u5B9A\u65F6\u5DE1\u822A\u6307\u4EE4-\u67E5\u8BE2\u914D\u7F6E\u548C\u5F00\u5173",
    "\u5B88\u671B\u70B9\u6307\u4EE4-\u67E5\u8BE2\u901A\u90530",
  };

  static const List<String> _ringtones = [
    "https://icam-media-cloud-user-public.tange365.com/alarm-bells/zh-cn/g711/welcome-o.wav",
    "https://icam-media-cloud-user-public.tange365.com/alarm-bells/zh-cn/g711/danger-of-water-depth-o.wav",
    "https://icam-media-cloud-user-public.tange365.com/alarm-bells/zh-cn/g711/no-parking-o.wav",
  ];

  static const int aitBodyDet = 0;
  static const int aitBodyTrace = 1;
  static const int aitFaceDet = 2;
  static const int aitFaceReco = 3;
  static const int aitSitPosture = 4;

  static const int aitmBodyDet = 1 << aitBodyDet;
  static const int aitmBodyTrace = 1 << aitBodyTrace;
  static const int aitmFaceDet = 1 << aitFaceDet;
  static const int aitmFaceReco = 1 << aitFaceReco;
  static const int aitmSitPosture = 1 << aitSitPosture;

  static const Map<int, String> _aiTypeNames = {
    aitmBodyDet: "人形检测",
    aitmBodyTrace: "人形追踪",
    aitmFaceDet: "人脸检测",
    aitmFaceReco: "人脸识别",
    aitmSitPosture: "坐姿检测"
  };

  final List<InstructOption> _instructOptions = [];

  late String _deviceId;
  late String _deviceName;

  late Pipe _pipe;

  bool _connected = false;
  bool _failed = false;
  bool _shouldKeepAwake = false;
  Map<String, dynamic>? _features;
  Set<String> _supportedSections = const {};
  bool _discoveringCapabilities = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
        child: _failed
            ? _retry()
            : (!_connected || _discoveringCapabilities
                ? createCenterLoading(size: 20.0)
                : _root()));
  }

  Widget _retry() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _pipe.establish();
        },
        child: const Text("点击重试",
            style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      ),
    );
  }

  void _onInstructSelected(InstructOption option) {
    if (!_pipe.isEstablished) {
      SnackTips.show(context, "连接未建立");
    } else {
      option.action();
    }
  }

  Future<void> _showResult(String title, String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
              child: ListBody(children: <Widget>[Text(content)])),
          actions: <Widget>[
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _root() {
    return Padding(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16.0),
      child: Column(
        children: [
          SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
                itemCount: _instructOptions.length,
                itemBuilder: (context, index) => _instructOptionCard(index)),
          ),
        ],
      ),
    );
  }

  Widget _instructOptionCard(int index) => _instructOptions[index].group
      ? _instructGroup(index)
      : _instructCard(index);

  InkWell _instructCard(int index) {
    final option = _instructOptions[index];
    final hasDesc = option.desc != null && option.desc!.isNotEmpty;

    return InkWell(
      onTap: () => _onInstructSelected(option),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        padding:
            EdgeInsets.only(left: 16.0, top: 12.0, right: 16.0, bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: index == 1
                  ? SampleThemeConfigure.colorPrimary
                  : Colors.transparent,
              width: 1.0),
        ),
        child: Row(
          children: [
            Icon(Icons.send_rounded,
                color: SampleThemeConfigure.colorPrimary, size: 16),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: hasDesc
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.center,
                children: [
                  Text(option.identifier,
                      style: TextStyle(
                          fontSize: 12,
                          color: SampleThemeConfigure.colorTextPrimary)),
                  if (hasDesc) ...[
                    SizedBox(height: 4.0),
                    Text(option.desc!,
                        style: TextStyle(
                            fontSize: 10,
                            color: SampleThemeConfigure.colorTextPrimary
                                .withOpacity(0.6)))
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _instructGroup(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      padding: EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 0),
      decoration: BoxDecoration(
          color: Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _instructOptions[index].identifier,
                  style: TextStyle(
                      fontSize: 14,
                      color: SampleThemeConfigure.colorTextPrimary,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;

    WidgetsBinding.instance.addObserver(this);

    _prepareOptions();
    _preparePipe();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pipe.establish();
    });
  }

  void _preparePipe() {
    _pipe = Pipe.create(_deviceId);
    // IMPORTANT: Only use TCP mode (1) when remote device explicitly supports it and there is a clear requirement
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _pipe.listen((state) {
      setState(() {
        _failed = state == PipeState.failed;
        _connected = state == PipeState.established;
        _discoveringCapabilities = _connected;
        if (!_connected) {
          _supportedSections = const {};
          _prepareOptions();
        }
      });

      widget.onConnectionStateChanged?.call(_connected, _failed);

      if (state == PipeState.established) {
        _onPipeEstablished();
      }
    });
  }

  void _onPipeEstablished() async {
    try {
      final resp = await SpecService.primary(_deviceId);
      if (resp.success && resp.data != null) {
        if (_checkWakeupAbility(resp.data!.deviceAttributes)) {
          _shouldKeepAwake = true;
          await InstructStandard.keepAwake(_pipe);
          SnackTips.show(context, "这是低功耗设备，已自动发送保持唤醒指令。");
        }
      }
    } catch (e) {
      // 静默处理错误，不影响正常功能
    }

    if (!mounted || !_pipe.isEstablished) return;
    await _refreshCapabilities();
  }

  Future<void> _refreshCapabilities() async {
    Map<String, dynamic>? features;
    try {
      final ability = await InstructStandard.ability(_pipe);
      if (ability.success) features = ability.data?.features;
    } catch (_) {}
    final probes = <MapEntry<String, Future<bool> Function()>>[
      MapEntry(
          "\u4E91\u53F0",
          () async =>
              (await InstructStandard.currentPtzPosition(_pipe)).success),
      MapEntry("\u9884\u7F6E\u4F4D", () async {
        final resp = await InstructStandard.presetSpec(_pipe);
        return resp.success && (resp.data?.max ?? 0) > 0;
      }),
      MapEntry("\u89C6\u9891\u6E05\u6670\u5EA6", () async {
        final resp = await InstructStandard.quality(_pipe);
        return resp.success && (resp.data?.isNotEmpty ?? false);
      }),
      MapEntry("\u5B58\u50A8\u5361",
          () async => (await InstructStandard.storageState(_pipe)).success),
      MapEntry("\u7535\u6C60\u72B6\u6001",
          () async => (await InstructStandard.batteryState(_pipe)).success),
      MapEntry("PIR",
          () async => (await InstructStandard.pirSensitivity(_pipe)).success),
      MapEntry("\u72B6\u6001\u706F-LED",
          () async => (await InstructStandard.ledState(_pipe)).success),
      MapEntry("\u7535\u6E90\u9891\u7387",
          () async => (await InstructStandard.powerHz(_pipe)).success),
      MapEntry("Wi-Fi", () async {
        if ((await InstructStandard.currentWifi(_pipe)).success) return true;
        return (await InstructStandard.listNearbyWifi(_pipe)).success;
      }),
      MapEntry(
          "\u7F51\u7EDC\u4E0E\u4FE1\u53F7",
          () async =>
              (await InstructStandard.currentNetworkState(_pipe)).success),
      MapEntry("\u7F51\u7EDC\u914D\u7F6E",
          () async => (await InstructStandard.remoteIpConfig(_pipe)).success),
      MapEntry("\u753B\u9762",
          () async => (await InstructStandard.picture(_pipe)).success),
      MapEntry("\u767D\u5149\u706F",
          () async => (await InstructStandard.light(_pipe)).success),
      MapEntry("\u591C\u89C6",
          () async => (await InstructStandard.nightVision(_pipe)).success),
      MapEntry("\u5F55\u50CF",
          () async => (await InstructStandard.recordingProfile(_pipe)).success),
      MapEntry("\u5F00\u5173",
          () async => (await InstructStandard.deviceSwitch(_pipe)).success),
      MapEntry("\u955C\u5934\u5173\u95ED\u8BA1\u5212",
          () async => (await InstructStandard.shutdownPlans(_pipe)).success),
      MapEntry("\u5587\u53ED",
          () async => (await InstructStandard.volumeState(_pipe)).success),
      MapEntry("\u9EA6\u514B\u98CE",
          () async => (await InstructStandard.microphoneSwitch(_pipe)).success),
      MapEntry("\u4E8B\u4EF6\u4FA6\u6D4B", () async {
        if ((await InstructStandard.eventState(_pipe, 3)).success) return true;
        return (await InstructStandard.eventState(_pipe, 4)).success;
      }),
      MapEntry("AI\u529F\u80FD\u5F00\u5173",
          () async => (await InstructStandard.currentAiState(_pipe)).success),
      MapEntry(
          "\u79FB\u52A8\u8FFD\u8E2A",
          () async =>
              (await InstructStandard.motionTrackingState(_pipe)).success),
      MapEntry(
          "\u79FB\u52A8\u4FA6\u6D4B",
          () async =>
              (await InstructStandard.motionDetectState(_pipe)).success),
      MapEntry("\u5BA0\u7269\u5582\u98DF", () async {
        final resp = await InstructStandard.feedingSpec(_pipe);
        return resp.success && (resp.data?.maxServingCount ?? 0) > 0;
      }),
      MapEntry("\u8B66\u6212\u8BED\u97F3",
          () async => (await InstructStandard.alarmState(_pipe)).success),
      MapEntry("\u7535\u6E90\u7B56\u7565",
          () async => (await InstructStandard.powerStrategy(_pipe)).success),
      MapEntry(
          "\u4F11\u7720\u6307\u4EE4-\u67E5\u8BE2\u6700\u5927\u5524\u9192\u65F6\u957F",
          () async => (await InstructStandard.maxAwakeTime(_pipe)).success),
      MapEntry(
          "\u5C4F\u5E55\u663E\u793A\u6307\u4EE4-\u67E5\u8BE2\u663E\u793A\u65F6\u957F",
          () async =>
              (await InstructStandard.screenDisplayTime(_pipe)).success),
      MapEntry("OSD\u6307\u4EE4-\u67E5\u8BE2\u901A\u90530",
          () async => (await InstructStandard.osd(_pipe)).success),
      MapEntry(
          "\u79FB\u52A8\u4FA6\u6D4B\u533A\u57DF\u6307\u4EE4-\u67E5\u8BE2\u901A\u90530",
          () async => (await InstructStandard.motionDetectArea(_pipe)).success),
      MapEntry(
          "\u5DE1\u822A\u6307\u4EE4-\u67E5\u8BE2\u80FD\u529B\u548C\u8F68\u8FF9",
          () async => (await InstructStandard.cruiseAbility(_pipe)).success),
      MapEntry(
          "\u5B9A\u65F6\u5DE1\u822A\u6307\u4EE4-\u67E5\u8BE2\u914D\u7F6E\u548C\u5F00\u5173",
          () async => (await InstructStandard.timedCruise(_pipe)).success),
      MapEntry("\u5B88\u671B\u70B9\u6307\u4EE4-\u67E5\u8BE2\u901A\u90530",
          () async => (await InstructStandard.watchPoint(_pipe)).success),
    ];
    final results = <MapEntry<String, bool>>[];
    for (final probe in probes) {
      if (!_pipe.isEstablished) return;
      results.add(await _probeSection(probe.key, probe.value));
    }
    if (!mounted || !_pipe.isEstablished) return;
    final supported =
        results.where((entry) => entry.value).map((entry) => entry.key).toSet();
    if (supported.contains("\u4E91\u53F0")) supported.add("\u53D8\u7126");
    if (supported.any(_conditionalOptions.contains)) {
      supported.add("\u6269\u5C55\u6307\u4EE4\u6D4B\u8BD5");
    }
    setState(() {
      _features = features;
      _supportedSections = supported;
      _discoveringCapabilities = false;
      _prepareOptions();
    });
  }

  Future<MapEntry<String, bool>> _probeSection(
      String section, Future<bool> Function() request) async {
    try {
      return MapEntry(section, await request());
    } catch (_) {
      return MapEntry(section, false);
    }
  }

  void _applyPrimaryChannelFeatures(Map<String, dynamic>? features) {
    setState(() {
      _features = features;
      _prepareOptions();
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (_shouldKeepAwake) {
      InstructStandard.leaveAwake(_pipe);
    }

    _pipe.abolish();
    _pipe.destroy();

    WidgetsBinding.instance.removeObserver(this);
  }

  void _prepareOptions() {
    _instructOptions.clear();

    _instructOptions
        .add(InstructOption("指令通道", () => _onInstructDefault(), group: true));
    _instructOptions.add(
      InstructOption("使用自定义指令", () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InstructChannelPage(
                deviceId: _deviceId, deviceName: _deviceName),
          ),
        );
      }),
    );

    _instructOptions
        .add(InstructOption("设备能力", () => _onInstructDefault(), group: true));
    _instructOptions.add(InstructOption("设备能力-查询", () => _onInstructAbility()));

    _instructOptions
        .add(InstructOption("主通道", () => _onInstructDefault(), group: true));
    _instructOptions.add(
        InstructOption("主通道-查询当前通道", () => _onInstructGetPrimaryChannel()));
    final primaryChannelCount =
        PrimaryChannelCapability.handledChannelCount(_features);
    _instructOptions
        .add(InstructOption("主通道-设置为0", () => _onInstructSetPrimaryChannel(0)));
    if (primaryChannelCount > 1) {
      _instructOptions.add(
          InstructOption("主通道-设置为1", () => _onInstructSetPrimaryChannel(1)));
    }
    if (primaryChannelCount > 2) {
      _instructOptions.add(
          InstructOption("主通道-设置为2", () => _onInstructSetPrimaryChannel(2)));
    }

    _instructOptions
        .add(InstructOption("云台", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("云台-摄像头0-重置云台位置", () => _onInstructPtzReset()));
    _instructOptions.add(InstructOption("云台-摄像头0-持续移动-向左",
        () => _onInstructPtzMoveByContinuous(Direction.left)));
    _instructOptions.add(InstructOption("云台-摄像头0-持续移动-向右",
        () => _onInstructPtzMoveByContinuous(Direction.right)));
    _instructOptions.add(InstructOption(
        "云台-摄像头0-持续移动-向上", () => _onInstructPtzMoveByContinuous(Direction.up)));
    _instructOptions.add(InstructOption("云台-摄像头0-持续移动-向下",
        () => _onInstructPtzMoveByContinuous(Direction.down)));
    _instructOptions.add(InstructOption(
        "云台-摄像头0-移动一步-向左", () => _onInstructPtzMoveByStep(Direction.left)));
    _instructOptions.add(InstructOption(
        "云台-摄像头0-移动一步-向右", () => _onInstructPtzMoveByStep(Direction.right)));
    _instructOptions.add(InstructOption(
        "云台-摄像头0-移动一步-向上", () => _onInstructPtzMoveByStep(Direction.up)));
    _instructOptions.add(InstructOption(
        "云台-摄像头0-移动一步-向下", () => _onInstructPtzMoveByStep(Direction.down)));
    _instructOptions
        .add(InstructOption("云台-摄像头0-停止移动", () => _onInstructPtzStopMoving()));
    _instructOptions.add(InstructOption(
        "云台-摄像头0-查询当前位置", () => _onInstructCurrentPtzPosition()));
    _instructOptions.add(InstructOption("云台-摄像头0-设置位置- 0.5, 0.5, 0.5",
        () => _onInstructSetPtzPosition(PtzPosition(0.5, 0.5, 0.5))));
    _instructOptions.add(InstructOption("云台-摄像头0-设置位置- 0.0, 0.0, 0.0",
        () => _onInstructSetPtzPosition(PtzPosition(0.0, 0.0, 0.0))));
    _instructOptions.add(InstructOption("云台-摄像头0-设置位置- 1.0, 1.0, 1.0",
        () => _onInstructSetPtzPosition(PtzPosition(1.0, 1.0, 1.0))));

    _instructOptions.add(InstructOption(
        "\u{6269}\u{5C55}\u{6307}\u{4EE4}\u{6D4B}\u{8BD5}",
        () => _onInstructDefault(),
        group: true));
    _instructOptions.add(InstructOption(
        "\u{4F11}\u{7720}\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{6700}\u{5927}\u{5524}\u{9192}\u{65F6}\u{957F}",
        () => _onInstructMaxAwakeTime()));
    _instructOptions.add(InstructOption(
        "\u{5C4F}\u{5E55}\u{663E}\u{793A}\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{663E}\u{793A}\u{65F6}\u{957F}",
        () => _onInstructScreenDisplayTime()));
    _instructOptions.add(InstructOption(
        "OSD\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{901A}\u{9053}0",
        () => _onInstructOsd()));
    _instructOptions.add(InstructOption(
        "\u{79FB}\u{52A8}\u{4FA6}\u{6D4B}\u{533A}\u{57DF}\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{901A}\u{9053}0",
        () => _onInstructMotionDetectArea()));
    _instructOptions.add(InstructOption(
        "\u{5DE1}\u{822A}\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{80FD}\u{529B}\u{548C}\u{8F68}\u{8FF9}",
        () => _onInstructCruise()));
    _instructOptions.add(InstructOption(
        "\u{5B9A}\u{65F6}\u{5DE1}\u{822A}\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{914D}\u{7F6E}\u{548C}\u{5F00}\u{5173}",
        () => _onInstructTimedCruise()));
    _instructOptions.add(InstructOption(
        "\u{5B88}\u{671B}\u{70B9}\u{6307}\u{4EE4}-\u{67E5}\u{8BE2}\u{901A}\u{9053}0",
        () => _onInstructWatchPoint()));

    _instructOptions
        .add(InstructOption("预置位", () => _onInstructDefault(), group: true));
    _instructOptions.add(InstructOption(
        "预置位-查询能力规格", () => _onInstructPresetSpec(),
        desc: "查看设备支持的预置位类型和 max"));
    _instructOptions.add(InstructOption(
        "预置位-查询已保存列表", () => _onInstructAllPresetPoints(),
        desc: "查看当前已经保存的预置位"));
    _instructOptions.add(InstructOption(
        "预置位-保存示例点1", () => _onInstructUpdatePresetPoint(1),
        desc: "按设备类型自动构造并保存编号1"));
    _instructOptions.add(InstructOption(
        "预置位-保存示例点2", () => _onInstructUpdatePresetPoint(2),
        desc: "按设备类型自动构造并保存编号2"));
    _instructOptions.add(InstructOption(
        "预置位-删除示例点1", () => _onInstructDeletePresetPoint(1),
        desc: "从当前列表里找到编号1并删除"));
    _instructOptions.add(InstructOption(
        "预置位-删除示例点2", () => _onInstructDeletePresetPoint(2),
        desc: "从当前列表里找到编号2并删除"));

    _instructOptions
        .add(InstructOption("视频清晰度", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("视频清晰度-查询", () => _onInstructQuality()));

    _instructOptions
        .add(InstructOption("存储卡", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("存储卡-查询状态", () => _onInstructStorageState()));
    _instructOptions
        .add(InstructOption("存储卡-查询有录像的日期", () => _onInstructRecordDates()));
    _instructOptions.add(
        InstructOption("存储卡-格式化-超时30秒", () => _onInstructStorageFormat(30)));
    _instructOptions.add(
        InstructOption("存储卡-格式化-超时60秒", () => _onInstructStorageFormat(60)));
    _instructOptions.add(
        InstructOption("存储卡-格式化-超时90秒", () => _onInstructStorageFormat(90)));
    _instructOptions.add(
        InstructOption("存储卡-格式化-超时120秒", () => _onInstructStorageFormat(120)));

    _instructOptions
        .add(InstructOption("变焦", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("变焦-连续放大", () => _onInstructZoomInContinuous()));
    _instructOptions
        .add(InstructOption("变焦-连续缩小", () => _onInstructZoomOutContinuous()));
    _instructOptions
        .add(InstructOption("变焦-停止连续变焦", () => _onInstructZoomStop()));
    _instructOptions
        .add(InstructOption("变焦-查询当前倍数", () => _onInstructCurrentZoomRatio()));
    _instructOptions.add(
        InstructOption("变焦-设置倍数- 1.0", () => _onInstructSetZoomRatio(1.0)));
    _instructOptions.add(
        InstructOption("变焦-设置倍数- 0.0", () => _onInstructSetZoomRatio(0.0)));

    _instructOptions
        .add(InstructOption("电池状态", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("电池状态-查询", () => _onInstructBatteryState()));

    _instructOptions
        .add(InstructOption("PIR", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("PIR-查询-灵敏度", () => _onInstructPirSensitivity()));
    _instructOptions.add(
        InstructOption("PIR-设置-关闭", () => _onInstructSetPirSensitivity(0)));
    _instructOptions.add(
        InstructOption("PIR-设置-低灵敏度", () => _onInstructSetPirSensitivity(1)));
    _instructOptions.add(
        InstructOption("PIR-设置-中灵敏度", () => _onInstructSetPirSensitivity(2)));
    _instructOptions.add(
        InstructOption("PIR-设置-高灵敏度", () => _onInstructSetPirSensitivity(3)));

    _instructOptions.add(
        InstructOption("状态灯-LED", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("LED-查询-状态", () => _onInstructLedState()));
    _instructOptions
        .add(InstructOption("LED-设置-打开", () => _onInstructSetLedState(1)));
    _instructOptions
        .add(InstructOption("LED-设置-关闭", () => _onInstructSetLedState(0)));

    _instructOptions
        .add(InstructOption("电源频率", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("电源频率-查询模式", () => _onInstructPowerHz()));
    _instructOptions
        .add(InstructOption("电源频率-设置为50Hz", () => _onInstructSetPowerHz(0)));
    _instructOptions
        .add(InstructOption("电源频率-设置为60Hz", () => _onInstructSetPowerHz(1)));

    _instructOptions
        .add(InstructOption("重启", () => _onInstructDefault(), group: true));
    _instructOptions.add(InstructOption("重启设备", () => _onInstructReboot()));

    _instructOptions
        .add(InstructOption("Wi-Fi", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("查询当前连接的 Wi-Fi", () => _onInstructCurrentWifi()));
    _instructOptions
        .add(InstructOption("查询附近的 Wi-Fi", () => _onInstructListNearbyWifi()));
    _instructOptions
        .add(InstructOption("更新设备连接的 Wi-Fi", () => _onInstructUpdateWifi()));

    _instructOptions
        .add(InstructOption("网络与信号", () => _onInstructDefault(), group: true));
    _instructOptions.add(
        InstructOption("查询当前网络状态", () => _onInstructCurrentNetworkState()));

    final remoteIpConfigA = RemoteIpConfig(
        "eth0",
        1,
        "192.168.1.100",
        "255.255.255.0",
        "192.168.1.1",
        "8.8.8.8",
        "8.8.4.4",
        "00:00:00:00:00:00");
    final remoteIpConfigB = RemoteIpConfig(
        "eth1",
        0,
        "172.168.1.101",
        "172.123.123.0",
        "172.168.1.1",
        "172.8.8.8",
        "172.8.4.4",
        "11:11:11:11:11:11");

    _instructOptions
        .add(InstructOption("网络配置", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("查询当前网络IP配置", () => _onInstructRemoteIpConfig()));
    _instructOptions.add(InstructOption(
        "设置网络IP配置A", () => _onInstructSetRemoteIpConfig(remoteIpConfigA)));
    _instructOptions.add(InstructOption(
        "设置网络IP配置B", () => _onInstructSetRemoteIpConfig(remoteIpConfigB)));

    _instructOptions
        .add(InstructOption("画面", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("画面-查询当前模式", () => _onInstructPicture()));
    _instructOptions
        .add(InstructOption("画面-设置为正常", () => _onInstructSetPicture(0)));
    _instructOptions
        .add(InstructOption("画面-设置-上下翻转", () => _onInstructSetPicture(1)));
    _instructOptions
        .add(InstructOption("画面-设置-左右镜像", () => _onInstructSetPicture(2)));
    _instructOptions
        .add(InstructOption("画面-设置-旋转180", () => _onInstructSetPicture(3)));

    _instructOptions
        .add(InstructOption("白光灯", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("白光灯-查询当前模式", () => _onInstructLight()));
    _instructOptions
        .add(InstructOption("白光灯-设置-关闭（白光灯不工作）", () => _onInstructSetLight(0)));
    _instructOptions
        .add(InstructOption("白光灯-设置-打开（全彩色）", () => _onInstructSetLight(1)));
    _instructOptions
        .add(InstructOption("白光灯-设置-智能（事件触发白光）", () => _onInstructSetLight(2)));

    _instructOptions
        .add(InstructOption("夜视", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("夜视-查询当前模式", () => _onInstructNightVision()));
    _instructOptions
        .add(InstructOption("夜视-设置-自动", () => _onInstructSetNightVision(0)));
    _instructOptions
        .add(InstructOption("夜视-设置-关闭", () => _onInstructSetNightVision(1)));
    _instructOptions
        .add(InstructOption("夜视-设置-始终开启", () => _onInstructSetNightVision(2)));

    _instructOptions
        .add(InstructOption("录像", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("录像-查询当前配置", () => _onInstructRecordingProfile()));
    _instructOptions.add(InstructOption(
        "录像-设置-清晰度- 0 高清", () => _onInstructRecordingProfileUpdateQuality(0)));
    _instructOptions.add(InstructOption(
        "录像-设置-清晰度- 1 标清", () => _onInstructRecordingProfileUpdateQuality(1)));
    _instructOptions.add(InstructOption(
        "录像-设置-录像模式 - 0 不录像", () => _onInstructRecordingProfileUpdateType(0)));
    _instructOptions.add(InstructOption(
        "录像-设置-录像模式 - 1 报警录像", () => _onInstructRecordingProfileUpdateType(1)));
    _instructOptions.add(InstructOption(
        "录像-设置-录像模式 - 2 全天录像", () => _onInstructRecordingProfileUpdateType(2)));
    _instructOptions.add(InstructOption(
        "录像-设置-录像模式 - 3 自动录像", () => _onInstructRecordingProfileUpdateType(3)));

    _instructOptions
        .add(InstructOption("开关", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("设备开关-查询", () => _onInstructSwitchState()));
    _instructOptions
        .add(InstructOption("设备开关-打开", () => _onInstructSetSwitchState(1)));
    _instructOptions
        .add(InstructOption("设备开关-关闭", () => _onInstructSetSwitchState(0)));

    final List<TimePlan> plansA = [];
    plansA.add(TimePlan(8, 0, 0, 10, 0, 0, [1, 3, 5], 1));
    final List<TimePlan> plansB = [];
    plansB.add(TimePlan(10, 0, 0, 12, 0, 0, [2, 4, 6], 1));
    plansB.add(TimePlan(19, 0, 0, 21, 0, 0, [1, 3, 5], 1));

    _instructOptions
        .add(InstructOption("镜头关闭计划", () => _onInstructDefault(), group: true));
    _instructOptions.add(
        InstructOption("镜头关闭计划-查询", () => _onInstructQueryShutdownPlans()));
    _instructOptions.add(InstructOption("镜头关闭计划-设置计划-1个计划",
        () => _onInstructSetShutdownPlans(TimePlans(plansA.length, plansA))));
    _instructOptions.add(InstructOption("镜头关闭计划-设置计划-2个计划",
        () => _onInstructSetShutdownPlans(TimePlans(plansB.length, plansB))));
    _instructOptions.add(InstructOption(
        "镜头关闭计划-清空计划", () => _onInstructSetShutdownPlans(TimePlans(0, []))));

    _instructOptions
        .add(InstructOption("喇叭", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("喇叭-查询状态", () => _onInstructVolumeState()));
    _instructOptions.add(InstructOption(
        "喇叭-设置-调节范围不可知-音量加", () => _onInstructSetVolumetate(false, 1)));
    _instructOptions.add(InstructOption(
        "喇叭-设置-调节范围不可知-音量减", () => _onInstructSetVolumetate(false, -1)));
    _instructOptions.add(InstructOption(
        "喇叭-设置-调节范围可知-音量设为100", () => _onInstructSetVolumetate(true, 100)));
    _instructOptions.add(InstructOption(
        "喇叭-设置-调节范围可知-音量设为50", () => _onInstructSetVolumetate(true, 50)));
    _instructOptions.add(InstructOption(
        "喇叭-设置-调节范围可知-音量设为0", () => _onInstructSetVolumetate(true, 0)));

    _instructOptions
        .add(InstructOption("麦克风", () => _onInstructDefault(), group: true));
    _instructOptions.add(InstructOption(
        "麦克风-查询-启用状态", () => _onInstructMicrophoneSwitchState()));
    _instructOptions.add(InstructOption(
        "麦克风-设置-启用麦克风", () => _onInstructSetMicrophoneSwitchState(1)));
    _instructOptions.add(InstructOption(
        "麦克风-设置-禁用麦克风", () => _onInstructSetMicrophoneSwitchState(0)));
    _instructOptions.add(InstructOption(
        "麦克风-查询-拾音灵敏度", () => _onInstructMicrophoneSensitivityState()));
    _instructOptions.add(InstructOption(
        "麦克风-设置-拾音灵敏度为100", () => _onInstructSetMicrophoneSensitivity(100)));
    _instructOptions.add(InstructOption(
        "麦克风-设置-拾音灵敏度为50", () => _onInstructSetMicrophoneSensitivity(50)));
    _instructOptions.add(InstructOption(
        "麦克风-设置-拾音灵敏度为0", () => _onInstructSetMicrophoneSensitivity(0)));

    _instructOptions
        .add(InstructOption("事件侦测", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("事件侦测-查询-声音", () => _onInstructEventState(3)));
    _instructOptions.add(
        InstructOption("事件侦测-开启-声音", () => _onInstructSetEventState(3, 1)));
    _instructOptions.add(
        InstructOption("事件侦测-关闭-声音", () => _onInstructSetEventState(3, 0)));
    _instructOptions
        .add(InstructOption("事件侦测-查询-PIR", () => _onInstructEventState(4)));
    _instructOptions.add(
        InstructOption("事件侦测-开启-PIR", () => _onInstructSetEventState(4, 1)));
    _instructOptions.add(
        InstructOption("事件侦测-关闭-PIR", () => _onInstructSetEventState(4, 0)));

    _instructOptions
        .add(InstructOption("AI功能开关", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("AI功能-查询-开关状态", () => _onInstructCurrentAiState()));
    _instructOptions.add(InstructOption(
        "AI功能-人形检测-启用", () => _onInstructSetAiState(aitmBodyDet, aitmBodyDet)));
    _instructOptions.add(InstructOption(
        "AI功能-人形检测-禁用", () => _onInstructSetAiState(aitmBodyDet, 0)));
    _instructOptions.add(InstructOption("AI功能-人形追踪-启用",
        () => _onInstructSetAiState(aitmBodyTrace, aitmBodyTrace)));
    _instructOptions.add(InstructOption(
        "AI功能-人形追踪-禁用", () => _onInstructSetAiState(aitmBodyTrace, 0)));
    _instructOptions.add(InstructOption(
        "AI功能-人脸检测-启用", () => _onInstructSetAiState(aitmFaceDet, aitmFaceDet)));
    _instructOptions.add(InstructOption(
        "AI功能-人脸检测-禁用", () => _onInstructSetAiState(aitmFaceDet, 0)));

    _instructOptions
        .add(InstructOption("移动追踪", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("移动追踪-查询", () => _onInstructMotionTrackingState()));
    _instructOptions
        .add(InstructOption("移动追踪-开启", () => _onInstructSetMptionTracking(1)));
    _instructOptions
        .add(InstructOption("移动追踪-关闭", () => _onInstructSetMptionTracking(0)));

    _instructOptions
        .add(InstructOption("移动侦测", () => _onInstructDefault(), group: true));
    _instructOptions.add(
        InstructOption("移动侦测-查询", () => _onInstructQueryMotionDetectState()));
    _instructOptions.add(InstructOption(
        "移动侦测-设置-开启-灵敏度1", () => _onInstructUpdateMotionDetectState(1, 1)));
    _instructOptions.add(InstructOption(
        "移动侦测-设置-开启-灵敏度3", () => _onInstructUpdateMotionDetectState(1, 3)));
    _instructOptions.add(InstructOption(
        "移动侦测-设置-开启-灵敏度5", () => _onInstructUpdateMotionDetectState(1, 5)));
    _instructOptions.add(InstructOption(
        "移动侦测-设置-关闭", () => _onInstructUpdateMotionDetectState(0, 0)));

    _instructOptions
        .add(InstructOption("宠物喂食", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("宠物喂食-查询喂养配置", () => _onInstructFeedSpec()));
    _instructOptions
        .add(InstructOption("宠物喂食-立即投喂-1份", () => _onInstructFeedPet(1)));
    _instructOptions
        .add(InstructOption("宠物喂食-立即投喂-3份", () => _onInstructFeedPet(3)));
    _instructOptions
        .add(InstructOption("宠物喂食-查询当前计划", () => _onInstructFeedSchedule()));
    final List<FeedingTimer> timersA = [];
    timersA.add(FeedingTimer(8, 0, 0, [1, 3, 5], 5, 1));
    _instructOptions.add(InstructOption(
        "宠物喂食-更新计划A",
        () => _onInstructSetFeedSchedule(
            FeedingSchedule(timersA.length, timersA))));

    final List<FeedingTimer> timersB = [];
    timersB.add(FeedingTimer(10, 0, 0, [2, 4, 6], 6, 1));

    timersB.add(FeedingTimer(19, 0, 0, [1, 3, 5], 3, 1));
    _instructOptions.add(InstructOption(
        "宠物喂食-更新计划B",
        () => _onInstructSetFeedSchedule(
            FeedingSchedule(timersB.length, timersB))));
    _instructOptions.add(InstructOption(
        "宠物喂食-清空计划", () => _onInstructSetFeedSchedule(FeedingSchedule(0, []))));

    _instructOptions
        .add(InstructOption("警戒语音", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("警戒语音-查询开启状态", () => _onInstructAlarmState()));
    _instructOptions
        .add(InstructOption("警戒语音-设置为开启", () => _onInstructSetAlarmState(1)));
    _instructOptions
        .add(InstructOption("警戒语音-设置为关闭", () => _onInstructSetAlarmState(0)));
    _instructOptions
        .add(InstructOption("警戒语音-立即播放", () => _onInstructPlayAlarmSound()));
    _instructOptions.add(InstructOption(
        "警戒语音-自定义-查询音频规格与当前铃声", () => _onInstructQueryRongtoneSpec()));
    _instructOptions.add(InstructOption(
        "警戒语音-自定义-设置为铃声-1", () => _onInstructQueryRongtoneUpdate(0)));
    _instructOptions.add(InstructOption(
        "警戒语音-自定义-设置为铃声-2", () => _onInstructQueryRongtoneUpdate(1)));
    _instructOptions.add(InstructOption(
        "警戒语音-自定义-设置为铃声-3", () => _onInstructQueryRongtoneUpdate(2)));
    _instructOptions.add(InstructOption(
        "警戒语音-自定义-设置为铃声-默认", () => _onInstructRongtoneUpdateDefault()));

    final List<TimePlan> powerPlansA = [];
    powerPlansA.add(TimePlan(8, 0, 0, 20, 0, 0, [1, 2, 3, 4, 5], 1));
    powerPlansA.add(TimePlan(22, 0, 0, 23, 0, 0, [0, 1, 2, 3, 4, 5, 6], 1));

    final List<TimePlan> powerPlansB1 = [];
    powerPlansB1.add(TimePlan(0, 0, 0, 23, 59, 59, [0, 6], 1));

    final List<TimePlan> powerPlansB2 = [];
    powerPlansB2.add(TimePlan(0, 0, 0, 23, 59, 59, [0, 6], 0));

    final List<TimePlan> powerPlansC = [];
    powerPlansC.add(TimePlan(6, 0, 0, 8, 0, 0, [1, 2, 3, 4, 5], 1));
    powerPlansC.add(TimePlan(12, 0, 0, 14, 0, 0, [1, 2, 3, 4, 5], 1));
    powerPlansC.add(TimePlan(18, 0, 0, 22, 0, 0, [0, 1, 2, 3, 4, 5, 6], 1));

    _instructOptions
        .add(InstructOption("电源策略", () => _onInstructDefault(), group: true));
    _instructOptions
        .add(InstructOption("电源策略-查询", () => _onInstructQueryPowerStrategy()));
    _instructOptions.add(InstructOption("电源策略-设置策略 A",
        () => _onInstructSetPowerStrategy(PowerStrategy(0, 0, 2, powerPlansA)),
        desc: "性能优先 2个计划 | 工作日8-20点 + 全周22-23点 | 计划启用"));
    _instructOptions.add(InstructOption(
        "电源策略-设置策略 B - 1",
        () =>
            _onInstructSetPowerStrategy(PowerStrategy(3, 20, 1, powerPlansB1)),
        desc: "用户定义录像时长 录20秒 1个计划 | 仅周末全天 | 计划启用"));
    _instructOptions.add(InstructOption(
        "电源策略-设置策略 B - 2",
        () =>
            _onInstructSetPowerStrategy(PowerStrategy(3, 15, 1, powerPlansB2)),
        desc: "用户定义录像时长 录15秒 1个计划 | 仅周末全天 | 计划不启用"));
    _instructOptions.add(InstructOption("电源策略-设置策略 C",
        () => _onInstructSetPowerStrategy(PowerStrategy(3, 25, 3, powerPlansC)),
        desc: "用户定义录像时长 录25秒 3个计划 | 工作日早中晚3时段 + 全周晚间 | 计划启用"));
    _instructOptions.add(InstructOption("电源策略-设置策略 D",
        () => _onInstructSetPowerStrategy(PowerStrategy(3, 10, 0, [])),
        desc: "3-用户定义录像时长 录10秒 0个计划 | 无计划（边界测试）"));
    _hideUnsupportedSections();
  }

  void _hideUnsupportedSections() {
    var currentSection = "";
    _instructOptions.removeWhere((option) {
      if (option.group) currentSection = option.identifier;
      final unsupportedSection =
          _conditionalSections.contains(currentSection) &&
              !_supportedSections.contains(currentSection);
      final unsupportedOption =
          _conditionalOptions.contains(option.identifier) &&
              !_supportedSections.contains(option.identifier);
      return unsupportedSection || unsupportedOption;
    });
  }

  void _onInstructDefault() async {
    _showResult("敬请期待", "对应示例正在开发中");
  }

  void _onInstructPtzReset() async {
    final resp = await InstructStandard.ptzReset(_pipe);
    if (resp.success) {
      _showResult("设置成功", "已发送重置指令");
    } else {
      _showResult("设置失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructPtzMoveByStep(Direction direction) async {
    final resp = await InstructStandard.ptzMoveByStep(_pipe, direction);
    if (resp.success) {
    } else {
      _showResult("设置失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructPtzMoveByContinuous(Direction direction) async {
    final resp = await InstructStandard.ptzMoveByContinuous(_pipe, direction);
    if (resp.success) {
    } else {
      _showResult("设置失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructPtzStopMoving() async {
    final resp = await InstructStandard.ptzStopMoving(_pipe);
    if (resp.success) {
    } else {
      _showResult("设置失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructCurrentPtzPosition() async {
    final resp = await InstructStandard.currentPtzPosition(_pipe);
    if (resp.success) {
      _showResult("查询成功",
          "位置-X: ${resp.data?.x}, 位置-Y: ${resp.data?.y}, 位置-Z: ${resp.data?.z}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructCurrentZoomRatio() async {
    final resp = await InstructStandard.zoomRatio(_pipe);
    if (resp.success) {
      _showResult("查询成功", "变焦倍数: ${resp.data}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetZoomRatio(double ratio) async {
    final ret = await InstructStandard.setZoomRatio(_pipe, ratio);
    if (ret.success) {
      _showResult("设置成功", "变焦倍数已更新");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructSetPtzPosition(PtzPosition position) async {
    final ret = await InstructStandard.setPtzPosition(_pipe, position);
    if (ret.success) {
      _showResult("设置成功", "云台位置已更新");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  String _formatExtensionData(Object? value) =>
      const convert.JsonEncoder.withIndent('  ').convert(value);

  void _showExtensionQuery<T>(
      String title, Resp<T> resp, Object? Function(T) format) {
    final data = resp.data;
    if (resp.success && data != null) {
      _showResult(title, _formatExtensionData(format(data)));
    } else {
      _showResult("\u{67E5}\u{8BE2}\u{5931}\u{8D25}",
          "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructMaxAwakeTime() async {
    final resp = await InstructStandard.maxAwakeTime(_pipe);
    _showExtensionQuery("\u{6700}\u{5927}\u{5524}\u{9192}\u{65F6}\u{957F}",
        resp, (value) => <String, dynamic>{"seconds": value});
  }

  void _onInstructScreenDisplayTime() async {
    final resp = await InstructStandard.screenDisplayTime(_pipe);
    _showExtensionQuery("\u{5C4F}\u{5E55}\u{663E}\u{793A}\u{65F6}\u{957F}",
        resp, (value) => <String, dynamic>{"seconds": value});
  }

  void _onInstructOsd() async {
    final resp = await InstructStandard.osd(_pipe);
    _showExtensionQuery("OSD", resp, (value) => value.toJson());
  }

  void _onInstructMotionDetectArea() async {
    final area = await InstructStandard.motionDetectArea(_pipe);
    if (!area.success || area.data == null) {
      _showExtensionQuery("\u{79FB}\u{52A8}\u{4FA6}\u{6D4B}\u{533A}\u{57DF}",
          area, (value) => value.toJson());
      return;
    }
    final visible = await InstructStandard.motionDetectAreaVisible(_pipe);
    if (!visible.success || visible.data == null) {
      _showExtensionQuery(
          "\u{79FB}\u{52A8}\u{4FA6}\u{6D4B}\u{533A}\u{57DF}\u{53EF}\u{89C1}\u{72B6}\u{6001}",
          visible,
          (value) => value);
      return;
    }
    _showResult(
        "\u{79FB}\u{52A8}\u{4FA6}\u{6D4B}\u{533A}\u{57DF}",
        _formatExtensionData(<String, dynamic>{
          "area": area.data!.toJson(),
          "visible": visible.data
        }));
  }

  void _onInstructCruise() async {
    final ability = await InstructStandard.cruiseAbility(_pipe);
    if (!ability.success || ability.data == null) {
      _showExtensionQuery(
          "\u{5DE1}\u{822A}\u{80FD}\u{529B}", ability, (value) => value);
      return;
    }
    final tracks = await InstructStandard.cruiseTracks(_pipe);
    if (!tracks.success || tracks.data == null) {
      _showExtensionQuery(
          "\u{5DE1}\u{822A}\u{8F68}\u{8FF9}", tracks, (value) => value);
      return;
    }
    final abilityData = ability.data!;
    final trackData = tracks.data!;
    _showResult(
      "\u{5DE1}\u{822A}",
      _formatExtensionData(<String, dynamic>{
        "ability": <String, dynamic>{
          "channel": abilityData.channel,
          "max_tracks": abilityData.maxTracks,
          "type": abilityData.type
        },
        "tracks": <String, dynamic>{
          "channel": trackData.channel,
          "type": trackData.type,
          "stay_time": trackData.stayTime,
          "active_track": trackData.activeTrack,
          "items": trackData.tracks
              .map((track) => <String, dynamic>{
                    "track_no": track.trackNo,
                    "preset_points": track.presetPoints,
                    "name": track.name,
                    "action": track.action
                  })
              .toList(),
        },
      }),
    );
  }

  void _onInstructTimedCruise() async {
    final config = await InstructStandard.timedCruise(_pipe);
    if (!config.success || config.data == null) {
      _showExtensionQuery("\u{5B9A}\u{65F6}\u{5DE1}\u{822A}", config,
          (value) => value.toJson());
      return;
    }
    final enabled = await InstructStandard.timedCruiseEnabled(_pipe);
    if (!enabled.success || enabled.data == null) {
      _showExtensionQuery("\u{5B9A}\u{65F6}\u{5DE1}\u{822A}\u{5F00}\u{5173}",
          enabled, (value) => value);
      return;
    }
    _showResult(
        "\u{5B9A}\u{65F6}\u{5DE1}\u{822A}",
        _formatExtensionData(<String, dynamic>{
          "config": config.data!.toJson(),
          "enabled": enabled.data
        }));
  }

  void _onInstructWatchPoint() async {
    final resp = await InstructStandard.watchPoint(_pipe);
    _showExtensionQuery(
        "\u{5B88}\u{671B}\u{70B9}", resp, (value) => value.toJson());
  }

  String _formatPresetRaw(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return "{}";
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String _presetTypeName(PresetType type) => type.toString().split(".").last;

  PresetPoint _buildPresetSamplePoint(PresetType type, int index) {
    switch (type) {
      case PresetType.byIndex:
        return PresetPoint(type, index, name: "Preset $index");
      case PresetType.byPosition:
        return PresetPoint(type, index,
            name: "Preset $index",
            coordinate: Coordinate(0.1 * index, 0.2 * index, 0.3 * index));
      case PresetType.byIndexNoName:
        return PresetPoint(type, index);
      case PresetType.byPositionNoName:
        return PresetPoint(type, index,
            coordinate: Coordinate(0.1 * index, 0.2 * index, 0.3 * index));
    }
  }

  Map<String, dynamic> _presetPointJson(PresetPoint point, {int channel = 0}) {
    final data = <String, dynamic>{
      "channel": channel,
      "type": _presetTypeName(point.type),
      "index": point.index
    };

    if (point.name != null) {
      data["name"] = point.name;
    }
    if (point.coordinate != null) {
      data["coordinate"] = <String, dynamic>{
        "x": point.coordinate!.x,
        "y": point.coordinate!.y,
        "z": point.coordinate!.z
      };
    }
    return data;
  }

  void _onInstructPresetSpec() async {
    final resp = await InstructStandard.presetSpec(_pipe);
    if (resp.success) {
      final ability = resp.data!;
      _showResult("预置位能力规格",
          "类型: ${_presetTypeName(ability.type)}\n最大编号: ${ability.max}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructAllPresetPoints() async {
    final resp = await InstructStandard.allPresetPoints(_pipe);
    if (resp.success) {
      final packet = resp.data!;
      final items = packet.array ?? const <PresetPoint>[];
      final itemJson = items.map((item) => _presetPointJson(item)).toList();
      _showResult(
          "预置位列表",
          "类型: ${_presetTypeName(packet.type)}\n数量: ${items.length}\n\n列表:\n${_formatPresetRaw(<String, dynamic>{
                "items": itemJson
              })}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructUpdatePresetPoint([int index = 1]) async {
    final abilityResp = await InstructStandard.presetSpec(_pipe);
    if (!abilityResp.success) {
      _showResult("设置失败",
          "无法查询能力 ${_readableCode(abilityResp.code)} ${abilityResp.message}");
      return;
    }

    final ability = abilityResp.data!;
    if (ability.max < index) {
      _showResult("设置失败", "设备返回的 max 小于 $index，无法设置编号 $index");
      return;
    }

    final point = _buildPresetSamplePoint(ability.type, index);
    final ret = await InstructStandard.updatePresetPoint(_pipe, point);
    if (ret.success) {
      _showResult("设置成功",
          "已按设备类型 ${_presetTypeName(ability.type)} 设置编号$index。\n\n请求数据:\n${_formatPresetRaw(_presetPointJson(point))}");
    } else {
      _showResult("设置失败", "${_readableCode(ret.code)} ${ret.message}");
    }
  }

  void _onInstructDeletePresetPoint([int index = 1]) async {
    final listResp = await InstructStandard.allPresetPoints(_pipe);
    if (!listResp.success) {
      _showResult(
          "删除失败", "无法查询列表 ${_readableCode(listResp.code)} ${listResp.message}");
      return;
    }

    final packet = listResp.data!;
    PresetPoint? target;
    for (final item in packet.array ?? const <PresetPoint>[]) {
      if (item.index == index) {
        target = item;
        break;
      }
    }

    if (target == null) {
      _showResult("删除失败", "编号$index不存在");
      return;
    }

    final ret = await InstructStandard.deletePresetPoint(_pipe, target);
    if (ret.success) {
      _showResult("删除成功",
          "已根据当前列表删除编号$index。\n\n请求数据:\n${_formatPresetRaw(_presetPointJson(target))}");
    } else {
      _showResult("删除失败", "${_readableCode(ret.code)} ${ret.message}");
    }
  }

  void _onInstructAlarmState() async {
    final resp = await InstructStandard.alarmState(_pipe);
    if (resp.success) {
      final state = resp.data ?? 0;
      _showResult("查询成功", "警报状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetAlarmState(int state) async {
    final ret = await InstructStandard.setAlarmState(_pipe, state);
    if (ret.success) {
      _showResult("设置成功", "警报状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructPlayAlarmSound() async {
    final ret = await InstructStandard.playAlarmSound(_pipe);
    if (ret.success) {
      _showResult("发送成功", "请等待设备播放警报声音");
    } else {
      _showResult("发送失败", _readableCode(ret.code));
    }
  }

  void _onInstructQueryRongtoneUpdate(int index) async {
    final content = await onlineRingtone(_ringtones[index]);
    if (content.isEmpty) {
      _showResult("设置失败", "无法获取铃声 $index");
      return;
    }

    final packet = RingtonePacket(index + 1, 0, 0, 52, content);

    final ret = await InstructStandard.setAlarmRingtone(_pipe, packet);
    if (ret.success) {
      _showResult("设置成功", "警报铃声已更新铃声 ID=${index + 1}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructRongtoneUpdateDefault() async {
    final packet = RingtonePacket(0, 0, 0, 0, "");

    final ret = await InstructStandard.setAlarmRingtone(_pipe, packet);
    if (ret.success) {
      _showResult("设置成功", "警报铃声已更新铃声为默认");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructQueryRongtoneSpec() async {
    final resp = await InstructStandard.ringtoneSpec(_pipe);
    if (resp.success) {
      _showResult(
        "查询成功",
        "当前的铃声ID: ${resp.data?.id}\\n\\n"
            "规格-音频采样率: ${resp.data?.sampleRate}\\n"
            "规格-通道数: ${resp.data?.channels}\\n"
            "规格-音频位深: ${resp.data?.bitDepth}\\n"
            "规格-大小限制（KB，0-表示未知）: ${resp.data?.limit}\\n"
            "规格-文件格式: ${resp.data?.format}\\n"
            "规格-音频编码: ${resp.data?.codec}",
      );
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  String _readableCode(int? code) {
    if (code == null) return "unknown";

    switch (code) {
      case 0:
        return "RESPONSE_SUCCESS";
      case 1:
        return "TRANSPORT_UNAVAILABLE";
      case 2:
        return "RESPONSE_TIMEOUT";
      case 3:
        return "DUPLICATE_INSTRUCT";
      case 4:
        return "FAILED_INSTRUCT";
      case 5:
        return "UNKNOWN";
      case 6:
        return "DEVICE_IN_PROGRESS";
      case 7:
        return "DEVICE_ERROR_HEADER";
      case 8:
        return "DEVICE_UNSUPPORT_CMD";
      case 9:
        return "DEVICE_INVALID_PARAM";
      case 10:
        return "DEVICE_LACK_OF_RESOURCE";
      case 11:
        return "DEVICE_ERROR_INTERNAL";
      case 12:
        return "DEVICE_NOT_ALLOWED";
      default:
        return "unknown($code)";
    }
  }

  bool _checkWakeupAbility(String? deviceAbilities) {
    if (deviceAbilities == null || deviceAbilities.isEmpty) return false;
    try {
      final json = jsonDecode(deviceAbilities) as Map<String, dynamic>;
      return json.containsKey('wakeup') && json['wakeup'] != null;
    } catch (e) {
      return false;
    }
  }

  String _parseAiState(int mask, int flags) {
    StringBuffer result = StringBuffer();

    result.writeln("支持的AI功能:");
    bool hasSupportedFeatures = false;

    _aiTypeNames.forEach((maskValue, name) {
      if (mask & maskValue != 0) {
        hasSupportedFeatures = true;
        bool isEnabled = flags & maskValue != 0;
        result.writeln("• $name: ${isEnabled ? '已启用' : '未启用'}");
      }
    });

    if (!hasSupportedFeatures) {
      result.writeln("• 无AI功能支持");
    }

    result.writeln();
    result.writeln("原始数据:");
    result.writeln("mask: $mask (0x${mask.toRadixString(16).toUpperCase()})");
    result.write("flags: $flags (0x${flags.toRadixString(16).toUpperCase()})");

    return result.toString();
  }

  void _onInstructCurrentAiState() async {
    final resp = await InstructStandard.currentAiState(_pipe);
    if (resp.success) {
      final mask = resp.data?.mask ?? 0;
      final flags = resp.data?.flags ?? 0;
      final parsedState = _parseAiState(mask, flags);
      _showResult("AI功能状态查询成功", parsedState);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetAiState(int mask, int flags) async {
    final ret = await InstructStandard.setAiState(_pipe, mask, flags);
    if (ret.success) {
      final actionDesc = flags & mask != 0 ? "启用" : "关闭";
      final featureName = _aiTypeNames[mask] ?? "未知功能";
      _showResult("设置成功", "$featureName已$actionDesc");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructMotionTrackingState() async {
    final resp = await InstructStandard.motionTrackingState(_pipe);
    if (resp.success) {
      final mode = resp.data?.mode ?? 0;
      final support = resp.data?.support ?? 0;
      String tips = support == 0 ? "不支持" : "支持";
      tips += "\\n当前模式: ${mode == 1 ? "开启" : "关闭"}";
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructEventState(int event) async {
    final resp = await InstructStandard.eventState(_pipe, event);
    if (resp.success) {
      _showResult("查询成功", "事件状态: ${resp.data == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetEventState(int event, int enabled) async {
    final ret = await InstructStandard.setEventState(_pipe, event, enabled);
    if (ret.success) {
      _showResult("设置成功", "事件状态: ${enabled == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructFeedPet(int count) async {
    final ret = await InstructStandard.feedPet(_pipe, count);
    if (ret.success) {
      _showResult("发送成功", "请等待设备完成投喂");
    } else {
      _showResult("发送失败", _readableCode(ret.code));
    }
  }

  void _onInstructSetFeedSchedule(FeedingSchedule schedule) async {
    final ret = await InstructStandard.setFeedingSchedule(_pipe, schedule);
    if (ret.success) {
      _showResult("设置成功", "投喂计划已更新");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructFeedSchedule() async {
    final resp = await InstructStandard.feedingSchedule(_pipe);
    if (resp.success) {
      final count = resp.data?.total ?? 0;
      String tips = "当前计划份数: $count\\n";
      for (var i = 0; i < count; i++) {
        final item = resp.data?.list?[i];
        if (item != null) {
          tips +=
              "\\n\\n第${i + 1}个计划 : ${item.hour}:${item.minute}:${item.second} 份数: ${item.servingCount}, 星期: ${item.repeatDays}, 启用: ${item.enabled == 1 ? "是" : "否"}";
        }
      }
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructFeedSpec() async {
    final resp = await InstructStandard.feedingSpec(_pipe);
    if (resp.success) {
      final maxServing = resp.data?.maxServingCount ?? 0;
      final maxTimers = resp.data?.maxTimerCount ?? 0;

      final tips = "最大投喂份数: $maxServing\\n"
          "最多可设置的定时器个数: $maxTimers";

      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructQueryShutdownPlans() async {
    final resp = await InstructStandard.shutdownPlans(_pipe);
    if (resp.success) {
      final count = resp.data?.total ?? 0;
      String tips = "当前计划个数: $count\\n";
      for (var i = 0; i < count; i++) {
        final item = resp.data?.list?[i];
        if (item != null) {
          tips +=
              "\\n\\n第${i + 1}个计划 : ${item.startHour}:${item.startMinute}:${item.startSecond} - ${item.endHour}:${item.endMinute}:${item.endSecond} 星期: ${item.repeatDays}, 启用: ${item.enabled == 1 ? "是" : "否"}";
        }
      }
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetShutdownPlans(TimePlans plans) async {
    final ret = await InstructStandard.setShutdownPlans(_pipe, plans);
    if (ret.success) {
      _showResult("设置成功", "镜头关闭计划已更新");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructRecordingProfileUpdateType(int type) async {
    final resp = await InstructStandard.recordingProfile(_pipe);
    if (resp.success) {
      final quality = resp.data?.recordQuality ?? 0;
      final newProfile = RecordingProfile(type, quality);
      final ret = await InstructStandard.setRecordingProfile(_pipe, newProfile);
      if (ret.success) {
        _showResult("设置成功", "录像模式: $type");
      } else {
        _showResult("设置失败", "${ret.code} ${ret.message}");
      }
    } else {
      _showResult(
          "设置失败", "无法查询到当前配置 ${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructRecordingProfileUpdateQuality(int quality) async {
    final resp = await InstructStandard.recordingProfile(_pipe);
    if (resp.success) {
      final recordType = resp.data?.recordType ?? 0;
      final newProfile = RecordingProfile(recordType, quality);
      final ret = await InstructStandard.setRecordingProfile(_pipe, newProfile);
      if (ret.success) {
        _showResult("设置成功", "录像清晰度: $quality");
      } else {
        _showResult("设置失败", "${ret.code} ${ret.message}");
      }
    } else {
      _showResult(
          "设置失败", "无法查询到当前配置 ${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSwitchState() async {
    final resp = await InstructStandard.deviceSwitch(_pipe);
    if (resp.success) {
      final state = resp.data ?? 0;
      _showResult("查询成功", "设备开关状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructMicrophoneSwitchState() async {
    final resp = await InstructStandard.microphoneSwitch(_pipe);
    if (resp.success) {
      final enabled = resp.data ?? 0;
      _showResult("查询成功", "麦克风状态: ${enabled == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("查询失败", _readableCode(resp.code));
    }
  }

  void _onInstructMicrophoneSensitivityState() async {
    final resp = await InstructStandard.microphoneSensitivity(_pipe);
    if (resp.success) {
      final value = resp.data ?? 0;
      _showResult("查询成功", "麦克风灵敏度: $value");
    } else {
      _showResult("查询失败", _readableCode(resp.code));
    }
  }

  void _onInstructSetMicrophoneSensitivity(int value) async {
    final ret = await InstructStandard.setMicrophoneSensitivity(_pipe, value);
    if (ret.success) {
      _showResult("设置成功", "麦克风灵敏度: $value");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructSetMicrophoneSwitchState(int state) async {
    final ret = await InstructStandard.setMicrophoneSwitch(_pipe, state);
    if (ret.success) {
      _showResult("设置成功", "麦克风状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructVolumeState() async {
    final resp = await InstructStandard.volumeState(_pipe);
    if (resp.success) {
      final rangeKnown = resp.data?.rangeKnown ?? 0;
      final volume = resp.data?.volume ?? 0;
      String tips = "";
      if (rangeKnown == 0) {
        tips = "调节范围不可知";
      } else {
        tips = "调节范围可知";
      }
      tips += "\\n当前音量: $volume";
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", _readableCode(resp.code));
    }
  }

  void _onInstructSetVolumetate(bool shouldKnown, int volume) async {
    final resp = await InstructStandard.volumeState(_pipe);
    if (resp.success) {
      final rangeKnown = resp.data?.rangeKnown ?? 0;

      if (rangeKnown == 0 && shouldKnown) {
        _showResult("设置失败", "调节范围不可知，只可加减音量");
        return;
      }

      if (rangeKnown == 1 && !shouldKnown) {
        _showResult("设置失败", "调节范围可知，应当传入音量值");
        return;
      }

      final newState = VolumeState(volume, rangeKnown);

      final ret = await InstructStandard.setVolumeState(_pipe, newState);
      if (ret.success) {
        _showResult("设置成功", "音量 $volume");
      } else {
        _showResult("设置失败", _readableCode(ret.code));
      }
    } else {
      _showResult("设置失败", "无法查询到当前配置，${_readableCode(resp.code)}");
    }
  }

  void _onInstructSetSwitchState(int state) async {
    final ret = await InstructStandard.setDeviceSwitch(_pipe, state);
    if (ret.success) {
      _showResult("设置成功", "设备开关状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructSetMptionTracking(int mode) async {
    final ret = await InstructStandard.setMotionTrackingState(_pipe, mode);
    if (ret.success) {
      _showResult("设置成功", "移动追踪状态: ${mode == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructQueryMotionDetectState() async {
    final ret = await InstructStandard.motionDetectState(_pipe);
    if (ret.success) {
      final enabled = ret.data?.enabled ?? 0;
      final sensitivity = ret.data?.sensitivity ?? 0;
      _showResult(
          "设置成功", "移动侦测状态: ${enabled == 1 ? "开启" : "关闭"}\\n灵敏度: $sensitivity");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructUpdateMotionDetectState(int enabled, int sensitivity) async {
    final ret = await InstructStandard.setMotionDetectState(
        _pipe, enabled, sensitivity);
    if (ret.success) {
      _showResult("设置成功", "点击上方查询验证结果");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructRecordingProfile() async {
    final resp = await InstructStandard.recordingProfile(_pipe);
    if (resp.success) {
      final recordType = resp.data?.recordType ?? 0;
      final recordQuality = resp.data?.recordQuality ?? 0;
      String tips = "";
      switch (recordType) {
        case 0:
          tips += "录像模式: 0 - 不录像";
          break;
        case 1:
          tips += "录像模式: 1 - 报警录像";
          break;
        case 2:
          tips += "录像模式: 2 - 全天录像";
          break;
        case 3:
          tips += "录像模式: 3 - 自动录像";
          break;
        default:
          tips += "录像模式: 未知";
          break;
      }

      switch (recordQuality) {
        case 0:
          tips += "\\n卡录像清晰度: 0 - 高清";
          break;
        case 1:
          tips += "\\n卡录像清晰度: 1 - 标清";
          break;
        default:
          tips += "\\n卡录像清晰度: 未知";
          break;
      }
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructPicture() async {
    final resp = await InstructStandard.picture(_pipe);
    if (resp.success) {
      final mode = resp.data?.mode ?? 0;
      switch (mode) {
        case 0:
          _showResult("查询成功", "画面模式: 正常模式");
          break;
        case 1:
          _showResult("查询成功", "画面模式: 上下翻转");
          break;
        case 2:
          _showResult("查询成功", "画面模式: 左右镜像");
          break;
        case 3:
          _showResult("查询成功", "画面模式: 旋转180");
          break;
        default:
          _showResult("查询成功", "画面模式: 未知");
          break;
      }
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructNightVision() async {
    final resp = await InstructStandard.nightVision(_pipe);
    if (resp.success) {
      final mode = resp.data?.mode ?? 0;
      final support = resp.data?.support ?? 0;
      String tips = "支持 $support 种模式";
      switch (mode) {
        case 0:
          tips += "\\n当前模式: 0 - 光线差时自动开启";
          break;
        case 1:
          tips += "\\n当前模式: 1 - 关闭夜视模式";
          break;
        case 2:
          tips += "\\n当前模式: 2 - 始终开启";
          break;
        default:
          tips += "\\n当前模式: 未知";
          break;
      }
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructLight() async {
    final resp = await InstructStandard.light(_pipe);
    if (resp.success) {
      final mode = resp.data?.mode ?? 0;
      final support = resp.data?.support ?? 0;
      String tips = "支持 $support 种模式";
      switch (mode) {
        case 0:
          tips += "\\n当前模式: 关闭（白光灯不工作）";
          break;
        case 1:
          tips += "\\n当前模式: 打开（全彩色）";
          break;
        case 2:
          tips += "\\n当前模式: 智能（事件触发白光）";
          break;
        default:
          tips += "\\n当前模式: 未知";
          break;
      }
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetLight(int mode) async {
    final ret = await InstructStandard.setLight(_pipe, mode);
    if (ret.success) {
      _showResult("设置成功", "灯光模式: $mode");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructSetNightVision(int mode) async {
    final ret = await InstructStandard.setNightVision(_pipe, mode);
    if (ret.success) {
      _showResult("设置成功", "夜视模式: $mode");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructSetPicture(int mode) async {
    final ret = await InstructStandard.setPicture(_pipe, mode);
    if (ret.success) {
      _showResult("设置成功", "画面模式: $mode");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructStorageFormat(int timeout) async {
    context.showSnackDialog(
      title: "注意",
      content: "确定要格式化存储卡吗？",
      onConfirm: () async {
        final ret =
            await InstructStandard.storageFormat(_pipe, timeout: timeout);
        if (ret.success) {
          _showResult("操作成功", "设备响应成功");
        } else {
          _showResult("操作失败", _readableCode(ret.code));
        }
      },
      onCancel: () {},
    );
  }

  void _onInstructCurrentWifi() async {
    final resp = await InstructStandard.currentWifi(_pipe);
    if (resp.success) {
      _showResult("查询成功", "名称: ${resp.data?.ssid}\\n信号: ${resp.data?.signal}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructListNearbyWifi() async {
    final resp = await InstructStandard.listNearbyWifi(_pipe);
    if (resp.success) {
      String tips = "";
      tips += "附近Wi-Fi: ${resp.data?.total} 个\\n";
      int index = 0;
      for (var item in resp.data?.list ?? []) {
        tips +=
            "\\n第 ${index++} 个: SSID: ${item.ssid}\\n信号: ${item.signal}\\n模式: ${item.mode}\\n加密类型: ${item.enctype}\\n状态: ${item.status}\\n";
      }
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructUpdateWifi() async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("更新Wi-Fi连接"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ssidController,
                  decoration: const InputDecoration(
                      labelText: "SSID *", hintText: "请输入Wi-Fi名称（必填）"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                      labelText: "密码", hintText: "请输入Wi-Fi密码（可为空）"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确认'),
              onPressed: () async {
                final ssid = ssidController.text.trim();
                final password = passwordController.text;

                if (ssid.isEmpty) {
                  Navigator.of(context).pop();
                  _showResult("输入错误", "SSID不能为空");
                  return;
                }

                Navigator.of(context).pop();

                final ret = await InstructStandard.updateRemoteWifi(
                    _pipe, ssid, password);
                if (ret.success) {
                  _showResult("设置成功", "新的Wi-Fi配置已发送给设备，请等待设备连接。");
                } else {
                  _showResult("设置失败", _readableCode(ret.code));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onInstructCurrentNetworkState() async {
    final resp = await InstructStandard.currentNetworkState(_pipe);
    if (resp.success) {
      _showResult(
          "查询成功", "网络类型: ${resp.data?.type}\\n信号: ${resp.data?.signal}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructRemoteIpConfig() async {
    final resp = await InstructStandard.remoteIpConfig(_pipe);
    if (resp.success) {
      _showResult(
        "查询成功",
        "intf: ${resp.data?.intf}\\nip: ${resp.data?.ip}\\nnetmask: ${resp.data?.netmask}\\ngateway: ${resp.data?.gateway}\\ndns1: ${resp.data?.dns1}\\ndns2: ${resp.data?.dns2}\\nmac: ${resp.data?.mac}\\nDHCP: ${resp.data?.enableDhcp}",
      );
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetRemoteIpConfig(RemoteIpConfig config) async {
    final ret = await InstructStandard.setRemoteIpConfig(_pipe, config);
    if (ret.success) {
      _showResult("设置成功", "可查询确认结果");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructReboot() async {
    context.showSnackDialog(
      title: "注意",
      content: "确定要重启吗？\\n重启期间将会断开连接。",
      onConfirm: () async {
        final ret = await InstructStandard.reboot(_pipe);
        if (ret.success) {
          _showResult("发送成功", "请等待设备完成重启");
        } else {
          _showResult("发送失败", _readableCode(ret.code));
        }
      },
      onCancel: () {},
    );
  }

  void _onInstructStorageState() async {
    final resp = await InstructStandard.storageState(_pipe);
    if (resp.success) {
      final total = resp.data?.total ?? 0;
      final free = resp.data?.free ?? 0;
      String tips = "";
      switch (total) {
        case 0:
          tips = "未检测到存储卡";
          break;
        case -1:
          tips = "卡状态错误，需要格式化";
          break;
        case -2:
          tips = "卡状态只读";
          break;
        case -3:
          tips = "正在格式化";
          break;
        case -4:
          tips = "正在初始化";
          break;
        default:
          tips = "总容量: $total, 剩余容量: $free";
          break;
      }

      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructAbility() async {
    final resp = await InstructStandard.ability(_pipe);
    if (resp.success) {
      if (mounted) _applyPrimaryChannelFeatures(resp.data?.features);
      _showResult("能力集查询成功", "${resp.data?.features}");
    } else {
      _showResult("能力集查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructQuality() async {
    final resp = await InstructStandard.quality(_pipe);
    if (resp.success) {
      String tips = "";
      resp.data?.forEach((quality) =>
          tips += "label=${quality.label} value=${quality.value}\\n");
      _showResult("清晰度查询成功", tips);
    } else {
      _showResult("清晰度查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructRecordDates() async {
    final resp = await InstructStandard.recordDates(_pipe);
    if (resp.success) {
      final count = resp.data?.total ?? 0;
      if (count == 0) {
        _showResult("查询成功", "未找到录像日期");
        return;
      }

      String tips = "录像日期 ($count 个):\\n";
      final dates = resp.data?.list ?? [];
      final displayCount = count > 10 ? 10 : count;

      for (int i = 0; i < displayCount; i++) {
        final date = dates[i];
        final dateStr =
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        tips += "$dateStr\\n";
      }

      if (count > 10) {
        tips += "...(仅显示前10个)";
      }

      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructZoomInContinuous() async {
    final ret = await InstructStandard.zoomInContinuous(_pipe);
    if (ret.success) {
      _showResult("发送成功", "变焦连续放大指令已发送");
    } else {
      _showResult("发送失败", _readableCode(ret.code));
    }
  }

  void _onInstructZoomOutContinuous() async {
    final ret = await InstructStandard.zoomOutContinuous(_pipe);
    if (ret.success) {
      _showResult("发送成功", "变焦连续缩小指令已发送");
    } else {
      _showResult("发送失败", _readableCode(ret.code));
    }
  }

  void _onInstructZoomStop() async {
    final ret = await InstructStandard.zoomStop(_pipe);
    if (ret.success) {
      _showResult("发送成功", "变焦停止指令已发送");
    } else {
      _showResult("发送失败", _readableCode(ret.code));
    }
  }

  void _onInstructBatteryState() async {
    final resp = await InstructStandard.batteryState(_pipe);
    if (resp.success) {
      final mode = resp.data?.mode ?? 0;
      final power = resp.data?.power ?? 0;
      final low = resp.data?.low ?? 0;
      String tips =
          "电源模式: $mode （0–放电中，1–充电中） \\n电池电量: $power% \\n低电: ${low == 1 ? "是" : "否"}";
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructPirSensitivity() async {
    final resp = await InstructStandard.pirSensitivity(_pipe);
    if (resp.success) {
      final sensitivity = resp.data ?? 0;
      String level = "";
      switch (sensitivity) {
        case 0:
          level = "关闭";
          break;
        case 1:
          level = "低";
          break;
        case 2:
          level = "中";
          break;
        case 3:
          level = "高";
          break;
        default:
          level = "未知";
          break;
      }
      _showResult("查询成功", "PIR传感器灵敏度: $level ($sensitivity)");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetPirSensitivity(int sensitivity) async {
    final ret = await InstructStandard.setPirSensitivity(_pipe, sensitivity);
    if (ret.success) {
      String level = "";
      switch (sensitivity) {
        case 0:
          level = "关闭";
          break;
        case 1:
          level = "低";
          break;
        case 2:
          level = "中";
          break;
        case 3:
          level = "高";
          break;
        default:
          level = "未知";
          break;
      }
      _showResult("设置成功", "PIR传感器灵敏度: $level");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructLedState() async {
    final resp = await InstructStandard.ledState(_pipe);
    if (resp.success) {
      final state = resp.data ?? 0;
      _showResult("查询成功", "LED指示灯状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetLedState(int state) async {
    final ret = await InstructStandard.setLedState(_pipe, state);
    if (ret.success) {
      _showResult("设置成功", "LED指示灯状态: ${state == 1 ? "开启" : "关闭"}");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  void _onInstructPowerHz() async {
    final resp = await InstructStandard.powerHz(_pipe);
    if (resp.success) {
      final mode = resp.data ?? 0;
      String frequency = mode == 0
          ? "50Hz"
          : mode == 1
              ? "60Hz"
              : "未知";
      _showResult("查询成功", "电源频率模式: $frequency ($mode)");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetPowerHz(int mode) async {
    final ret = await InstructStandard.setPowerHz(_pipe, mode);
    if (ret.success) {
      String frequency = mode == 0
          ? "50Hz"
          : mode == 1
              ? "60Hz"
              : "未知";
      _showResult("设置成功", "电源频率模式: $frequency");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }

  Future<String> onlineRingtone(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    } else {
      _showResult("下载失败", "错误码 ${response.statusCode}");
      return "";
    }
  }

  void _onInstructGetPrimaryChannel() async {
    final resp = await InstructStandard.primaryChannel(_pipe);
    if (resp.success) {
      final channel = resp.data ?? 0;
      _showResult("查询成功", "当前主通道: $channel");
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetPrimaryChannel(int channel) async {
    final ability = await InstructStandard.ability(_pipe);
    if (!mounted) return;

    final features = ability.success ? ability.data?.features : _features;
    if (ability.success) _applyPrimaryChannelFeatures(features);
    if (!PrimaryChannelCapability.supports(features, channel)) {
      final count = PrimaryChannelCapability.handledChannelCount(features);
      _showResult("\u{4E0D}\u{652F}\u{6301}\u{7684}\u{901A}\u{9053}",
          "\u{8BF7}\u{6C42}: $channel, \u{53EF}\u{7528}: 0-${count - 1}");
      return;
    }

    final ret = await InstructStandard.setPrimaryChannel(_pipe, channel);
    if (!mounted) return;
    if (!ret.success) {
      _showResult("设置失败", _readableCode(ret.code));
      return;
    }

    final current = await InstructStandard.primaryChannel(_pipe);
    if (!mounted) return;
    if (!current.success) {
      _showResult("\u{6821}\u{9A8C}\u{5931}\u{8D25}",
          "${_readableCode(current.code)} ${current.message}");
      return;
    }
    if (current.data != channel) {
      _showResult("\u{6821}\u{9A8C}\u{5931}\u{8D25}",
          "\u{8BF7}\u{6C42}: $channel, \u{5F53}\u{524D}: ${current.data}");
      return;
    }

    _showResult("设置成功", "主通道已设置为: $channel");
  }

  void _onInstructQueryPowerStrategy() async {
    final resp = await InstructStandard.powerStrategy(_pipe);
    if (resp.success) {
      final strategy = resp.data?.strategy ?? 0;
      final recLen = resp.data?.recLen ?? 0;
      final planCount = resp.data?.planCount ?? 0;
      String tips = "工作模式: $strategy\n录像时长: $recLen 秒\n计划个数: $planCount\n";
      for (var i = 0; i < planCount; i++) {
        final item = resp.data?.planList?[i];
        if (item != null) {
          tips +=
              "\n第${i + 1}个计划: ${item.startHour}:${item.startMinute}:${item.startSecond} - ${item.endHour}:${item.endMinute}:${item.endSecond} 星期: ${item.repeatDays}, 启用: ${item.enabled == 1 ? "是" : "否"}";
        }
      }
      tips += "\n\n工作模式说明:\n"
          "0 - 性能优先\n"
          "1 - 省电模式\n"
          "2 - 超级省电模式\n"
          "3 - 用户定义录像时长\n";
      tips += "\n\n星期格式说明:\n\n0-周日，1-周一，2-周二，3-周三，4-周四，5-周五，6-周六\n";
      _showResult("查询成功", tips);
    } else {
      _showResult("查询失败", "${_readableCode(resp.code)} ${resp.message}");
    }
  }

  void _onInstructSetPowerStrategy(PowerStrategy strategy) async {
    final ret = await InstructStandard.setPowerStrategy(_pipe, strategy);
    if (ret.success) {
      _showResult("设置成功", "电源策略已更新");
    } else {
      _showResult("设置失败", _readableCode(ret.code));
    }
  }
}

class InstructOption {
  final String identifier;
  final Function() action;
  final String? desc;
  bool group = false;

  InstructOption(this.identifier, this.action, {this.group = false, this.desc});
}
