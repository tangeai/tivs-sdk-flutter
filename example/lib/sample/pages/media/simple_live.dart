part of '../rapid_kit_sample_pages.dart';

/// 一个简单的直播播放页面
class SimpleLivePage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String? deviceAbilities;

  const SimpleLivePage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.deviceAbilities,
  });

  @override
  State<SimpleLivePage> createState() => _SimpleLivePageState();
}

class _SimpleLivePageState extends LifecycleAwareState<SimpleLivePage> {
  late String _deviceId;
  late String _deviceName;

  /// P2P连接实例
  late Pipe _pipe;

  /// 负责直播流的获取
  late LiveStream _liveStream;

  /// 播放器，负责音视频解码、缓冲管理、音画同步、渲染输出
  late Player _player;

  bool _rendering = false;
  bool _establishFailed = false;

  @override
  Widget build(BuildContext context) => _scaffold(
      _deviceName.isEmpty ? _deviceId : _deviceName,
      context,
      _buildContent(),
      _deviceId,
      _deviceName);

  Widget _buildContent() => Container(
        color: SampleThemeConfigure.colorVideoBackground,
        child: _buildPlayer(),
      );

  Widget _buildPlayer() {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            // Player 提供的 Widget，用于展示视频画面
            child: _player.texture(),
          ),
        ),
        if (!_rendering && !_establishFailed) createBufferingWidget(),
        if (_establishFailed) _establishFailedWidget(),
      ],
    );
  }

  Widget _establishFailedWidget() {
    return EstablishFailedWidget(
      onRetry: () {
        // 点击后，走统一恢复入口，避免只重连不恢复播放
        start();
        setState(() => _establishFailed = false);
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;

    /// 初始化三大核心模块
    _prepareComponents();
  }

  /// 页面可见时启动播放
  @override
  void start() {
    // 恢复时尝试重新建立连接（P2P 可能会由于处于后台等原因被系统断开）
    if (!_pipe.isEstablished) {
      _pipe.establish();
    }
    _liveStream.start();
    _player.start();
  }

  /// 页面不可见时停止播放
  @override
  void stop() {
    _liveStream.stop();
    _player.stop();
  }

  /// 退出页面的时候，销毁清理资源
  @override
  void dispose() {
    super.dispose();

    // 下方资源存在依赖关系： player -> liveStream -> pipe，
    // 请注意释放顺序，确保安全释放
    // 顺序错乱将导致底层指针失效，造成闪退

    // 1. 先停止和销毁播放器
    _player.stop();
    _player.destroy();

    // 2. 再停止和销毁直播流
    _liveStream.stop();
    _liveStream.destroy();

    // 3. 最后断开和销毁 P2P
    _pipe.abolish();
    _pipe.destroy();

    WidgetsBinding.instance.removeObserver(this);
  }

  void _prepareComponents() async {
    // 1. 初始化 P2P
    _pipe = Pipe.create(_deviceId);
    // IMPORTANT: Only use TCP mode (1) when remote device explicitly supports it and there is a clear requirement
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _pipe.listen((state) {
      if (state == PipeState.established) {
        // 连接建立成功，可在此发送指令等
      } else if (state == PipeState.failed) {
        // 连接失败，可在此进行提示或者发起重试
        setState(() => _establishFailed = true);
      } else {
        // 其他状态（连接中、断开等）
        setState(() {
          _establishFailed = false;
          _rendering = false;
        });
      }
    });

    // 2. 初始化 LiveStream
    final streamAudioEnabled =
        DeviceAudioCapability.streamAudioEnabledFromDeviceAbilities(
            widget.deviceAbilities);
    _liveStream =
        LiveStream.createPrimary(_pipe, enableAudio: streamAudioEnabled);

    // 按需设置清晰度，如 高清
    _liveStream.highQuality();

    // 3. 初始化 Player
    _player = _createSamplePlayer();
    _player.onRenderState = (state) {
      setState(() => _rendering = state != RenderState.buffering);
    };

    // 4. 准备播放器 - 建立 LiveStream 和 Player 的联系
    final provider = _liveStream.provider();
    if (provider != null) {
      await _player.prepare(provider);
    }
  }
}
