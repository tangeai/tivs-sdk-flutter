part of '../rapid_kit_sample_pages.dart';

class SimpleRtcPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const SimpleRtcPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<SimpleRtcPage> createState() => _SimpleRtcPageState();
}

class _SimpleRtcPageState extends LifecycleAwareState<SimpleRtcPage> {
  late String _deviceId;
  late String _deviceName;

  late Pipe _pipe;
  VoidCallback? _cancelPipeStateSubscription;

  bool _establishFailed = false;
  String _connectionStatus = "connecting";

  static const int _pingIntervalSeconds = 5;
  Timer? _pingTimer;
  Timer? _uiUpdateTimer;
  DateTime? _connectionEstablishedTime;
  DateTime? _lastPingTime;
  int _disconnectionCount = 0;

  static const bool _enableAutoTest = false;
  bool _isAutoTesting = false;
  int _autoTestCount = 0;
  Timer? _autoTestTimer;
  static const int _maxAutoTestCount = 1000;
  static const int _autoTestMinDelayMs = 10;
  static const int _autoTestMaxDelayMs = 6000;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            _deviceName.isEmpty ? _deviceId : _deviceName,
            style: const TextStyle(color: SampleThemeConfigure.colorPrimary, fontSize: 14),
          ),
          backgroundColor: SampleThemeConfigure.colorBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: SampleThemeConfigure.colorPrimary,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(50, 28),
                  side: const BorderSide(color: SampleThemeConfigure.colorPrimary, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => InstructOverlay.show(context, _deviceId, _deviceName),
                child: const Text("指令", style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        body: _buildContent(),
        backgroundColor: SampleThemeConfigure.colorBackground,
      );

  Widget _buildContent() => Column(
        children: [
          _buildStatusBar(),
          if (_connectionStatus == "established") _buildConnectionInfoBar(),
          Expanded(child: _buildCenterContent()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ObsWidget(deviceId: _deviceId),
            ),
          ),
          _buildBottomButton(),
        ],
      );

  Widget _buildStatusDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusText(),
          if (_establishFailed) ...[
            const SizedBox(height: 32),
            _buildRetryButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    String statusText;
    Color statusColor;
    Widget statusIcon;
    String? detailText;

    switch (_connectionStatus) {
      case "connecting":
        statusText = "正在连接...";
        statusColor = SampleThemeConfigure.colorTextHint;
        statusIcon = createCenterLoading(size: 24, color: SampleThemeConfigure.colorPrimary);
        if (_disconnectionCount > 0) {
          detailText = "历史断开次数：$_disconnectionCount";
        }
        break;
      case "established":
        statusText = "连接成功";
        statusColor = Colors.green;
        statusIcon = Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.green,
            size: 20,
          ),
        );
        // 详细信息现在显示在标题栏下方，这里不再显示
        break;
      case "failed":
        statusText = "连接失败";
        statusColor = Colors.red;
        statusIcon = Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: const Icon(
            Icons.close,
            color: Colors.red,
            size: 20,
          ),
        );
        if (_disconnectionCount > 0) {
          detailText = "历史断开次数：$_disconnectionCount";
        }
        break;
      default:
        statusText = "未知状态";
        statusColor = SampleThemeConfigure.colorTextHint;
        statusIcon = const Icon(
          Icons.help,
          color: SampleThemeConfigure.colorTextHint,
          size: 24,
        );
    }

    return Column(
      children: [
        statusIcon,
        const SizedBox(height: 16),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (detailText != null) ...[
          const SizedBox(height: 12),
          Text(
            detailText,
            style: const TextStyle(
              color: SampleThemeConfigure.colorTextHint,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    String statusText;

    switch (_connectionStatus) {
      case "connecting":
        statusColor = SampleThemeConfigure.colorTextSub;
        statusText = "connecting";
        break;
      case "established":
        statusColor = Colors.green;
        statusText = "established";
        break;
      case "failed":
        statusColor = Colors.red;
        statusText = "failed";
        break;
      case "disconnected":
        statusColor = SampleThemeConfigure.colorTextHint;
        statusText = "disconnected";
        break;
      default:
        statusColor = SampleThemeConfigure.colorTextHint;
        statusText = "unknown";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            "连接状态：",
            style: TextStyle(
              color: SampleThemeConfigure.colorTextSub,
              fontSize: 14,
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_connectionStatus == "established") {
      // 连接成功时不显示任何内容，信息已在上方显示
      return const SizedBox.shrink();
    } else if (_connectionStatus == "failed") {
      // 连接失败时显示错误图标和重试按钮
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(height: 32),
            _buildRetryButton(),
          ],
        ),
      );
    } else if (_connectionStatus == "connecting") {
      // 连接中显示加载动画
      return Center(
        child: createCenterLoading(size: 20, color: SampleThemeConfigure.colorPrimary),
      );
    } else {
      // disconnected 状态显示空内容
      return const SizedBox.shrink();
    }
  }

  String? _buildConnectionDetails() {
    if (_connectionEstablishedTime == null) return null;

    final now = DateTime.now();
    final duration = now.difference(_connectionEstablishedTime!);
    final seconds = duration.inSeconds;
    final minutes = duration.inMinutes;
    final hours = duration.inHours;

    String connectionTime;
    final formattedTime = "${hours.toString().padLeft(2, '0')}:"
        "${(minutes % 60).toString().padLeft(2, '0')}:"
        "${(seconds % 60).toString().padLeft(2, '0')}";
    connectionTime = "已保持连接 $formattedTime";

    if (_lastPingTime != null) {
      final timeFormat = _lastPingTime!.toString().substring(11, 19);
      connectionTime += "\n最后一次 PING 时间：$timeFormat";
    } else {
      connectionTime += "\n等待首次 PING...";
    }

    if (_disconnectionCount > 0) {
      connectionTime += "\n历史断开次数：$_disconnectionCount";
    }

    return connectionTime;
  }

  Widget _buildRetryButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        _pipe.establish();
        setState(() {
          _establishFailed = false;
          _connectionStatus = "connecting";
          _connectionEstablishedTime = null;
          _lastPingTime = null;
        });
        _stopPingTimer();
      },
      child: const Text(
        "重试连接",
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;

    _prepareComponents();
  }

  @override
  void start() {
    // 页面启动时自动开始连接
    if (!_pipe.isEstablished) {
      _pipe.establish();
    }
    _startUIUpdateTimer();
  }

  @override
  void stop() {
    _stopPingTimer();
    _stopUIUpdateTimer();
    _stopAutoTest();
  }

  @override
  void dispose() {
    _cancelPipeStateSubscription?.call();
    _cancelPipeStateSubscription = null;
    _stopPingTimer();
    _stopUIUpdateTimer();
    _stopAutoTest(updateState: false);
    _pipe.abolish();
    _pipe.destroy();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _prepareComponents() async {
    _pipe = Pipe.create(_deviceId);
    // IMPORTANT: Only use TCP mode (1) when remote device explicitly supports it and there is a clear requirement
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _cancelPipeStateSubscription = _pipe.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state == PipeState.established) {
          if (_connectionStatus != "established") {
            _connectionEstablishedTime = DateTime.now();
          }
          _connectionStatus = "established";
          _establishFailed = false;
          _startPingTimer();
        } else if (state == PipeState.failed) {
          if (_connectionStatus == "established") {
            _disconnectionCount++;
          }
          _connectionStatus = "failed";
          _establishFailed = true;
          _connectionEstablishedTime = null;
          _lastPingTime = null;
          _stopPingTimer();
        } else if (state == PipeState.attempting) {
          if (_connectionStatus == "established") {
            _disconnectionCount++;
          }
          _connectionStatus = "connecting";
          _establishFailed = false;
          _connectionEstablishedTime = null;
          _lastPingTime = null;
          _stopPingTimer();
        } else {
          if (_connectionStatus == "established") {
            _disconnectionCount++;
          }
          _connectionStatus = state.name;
          _establishFailed = false;
          _connectionEstablishedTime = null;
          _lastPingTime = null;
          _stopPingTimer();
        }
      });
    });
  }

  void _startPingTimer() {
    _stopPingTimer();
    // 立即发送第一次 PING
    _sendPing();
    // 然后启动定期 PING
    _pingTimer = Timer.periodic(Duration(seconds: _pingIntervalSeconds), (timer) {
      _sendPing();
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _startUIUpdateTimer() {
    _stopUIUpdateTimer();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionStatus == "established" && _connectionEstablishedTime != null) {
        setState(() {
          // This will trigger a rebuild to update the connection time display
        });
      }
    });
  }

  void _stopUIUpdateTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;
  }

  void _sendPing() async {
    if (_connectionStatus != "established") {
      _stopPingTimer();
      return;
    }

    try {
      final result = await InstructStandard.ability(_pipe);
      if (result.success) {
        if (mounted) {
          setState(() {
            _lastPingTime = DateTime.now();
          });
        }
      } else {
        Logging.w("SimpleRtcPage", "PING failed: ${result.message}");
      }
    } catch (e) {
      Logging.e("SimpleRtcPage", "PING exception: $e");
    }
  }

  void _startAutoTest() {
    setState(() {
      _isAutoTesting = true;
      _autoTestCount = 0;
    });
    _executeAutoTestCycle();
  }

  void _stopAutoTest({bool updateState = true}) {
    _autoTestTimer?.cancel();
    _autoTestTimer = null;
    if (!updateState) {
      _isAutoTesting = false;
      return;
    }
    setState(() => _isAutoTesting = false);
  }

  void _executeAutoTestCycle() {
    if (!_isAutoTesting || _autoTestCount >= _maxAutoTestCount) {
      _stopAutoTest();
      return;
    }

    final random = math.Random();
    final shouldConnect = random.nextBool();

    if (shouldConnect) {
      _pipe.establish();
    } else {
      _pipe.abolish();
      if (mounted) {
        setState(() {
          _connectionStatus = "disconnected";
          _establishFailed = false;
          _connectionEstablishedTime = null;
          _lastPingTime = null;
        });
      }
      _stopPingTimer();
    }

    setState(() {
      _autoTestCount++;
    });

    final delay = _autoTestMinDelayMs + random.nextInt(_autoTestMaxDelayMs - _autoTestMinDelayMs);
    _autoTestTimer = Timer(Duration(milliseconds: delay), _executeAutoTestCycle);
  }

  Widget _buildConnectionInfoBar() {
    if (_connectionEstablishedTime == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final duration = now.difference(_connectionEstablishedTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds;

    final formattedTime = "${hours.toString().padLeft(2, '0')}:"
        "${(minutes % 60).toString().padLeft(2, '0')}:"
        "${(seconds % 60).toString().padLeft(2, '0')}";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: SampleThemeConfigure.colorPrimary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // 连接时长行
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SampleThemeConfigure.colorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.timer,
                  size: 16,
                  color: SampleThemeConfigure.colorPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "已保持连接",
                style: TextStyle(
                  color: SampleThemeConfigure.colorTextSub,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                formattedTime,
                style: const TextStyle(
                  color: SampleThemeConfigure.colorTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // PING 时间行
          if (_lastPingTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.sync,
                    size: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "最后 PING",
                  style: TextStyle(
                    color: SampleThemeConfigure.colorTextSub,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _lastPingTime!.toString().substring(11, 19),
                  style: const TextStyle(
                    color: SampleThemeConfigure.colorTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],

          // 断开次数行（如果有）
          if (_disconnectionCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "历史断开",
                  style: TextStyle(
                    color: SampleThemeConfigure.colorTextSub,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  "$_disconnectionCount 次",
                  style: const TextStyle(
                    color: SampleThemeConfigure.colorTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    String buttonText;
    VoidCallback? onPressed;

    switch (_connectionStatus) {
      case "connecting":
        buttonText = "取消连接";
        onPressed = _isAutoTesting
            ? null
            : () {
                _pipe.abolish();
                setState(() {
                  _connectionStatus = "disconnected";
                  _establishFailed = false;
                  _connectionEstablishedTime = null;
                  _lastPingTime = null;
                });
                _stopPingTimer();
              };
        break;
      case "established":
        buttonText = "断开连接";
        onPressed = _isAutoTesting
            ? null
            : () {
                _pipe.abolish();
                setState(() {
                  _connectionStatus = "disconnected";
                  _establishFailed = false;
                  _connectionEstablishedTime = null;
                  _lastPingTime = null;
                  _disconnectionCount++;
                });
                _stopPingTimer();
              };
        break;
      case "failed":
      case "disconnected":
      default:
        buttonText = "连接";
        onPressed = _isAutoTesting
            ? null
            : () {
                _pipe.establish();
              };
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _enableAutoTest
          ? Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAutoTesting ? Colors.red : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: _isAutoTesting ? _stopAutoTest : _startAutoTest,
                    child: Text(
                      _isAutoTesting ? "停止测试 ($_autoTestCount/$_maxAutoTestCount)" : "自动测试",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SampleThemeConfigure.colorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: onPressed,
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SampleThemeConfigure.colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }
}
