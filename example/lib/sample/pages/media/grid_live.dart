part of '../rapid_kit_sample_pages.dart';

class _GridLiveItemWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String? deviceAbilities;

  const _GridLiveItemWidget({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.deviceAbilities,
  });

  @override
  State<_GridLiveItemWidget> createState() => _GridLiveItemWidgetState();
}

class _GridLiveItemWidgetState extends State<_GridLiveItemWidget> {
  late Pipe _pipe;
  late LiveStream _liveStream;
  late Player _player;

  bool _isVisible = false;
  bool _isRendering = false;
  bool _establishFailed = false;

  @override
  void initState() {
    super.initState();
    _prepareComponents();
  }

  @override
  void dispose() {
    _player.stop();
    _player.destroy();
    _liveStream.stop();
    _liveStream.destroy();
    _pipe.abolish();
    _pipe.destroy();
    super.dispose();
  }

  void setVisible(bool visible) {
    if (_isVisible == visible) return;
    setState(() => _isVisible = visible);
    visible ? _startPlayback() : _stopPlayback();
  }

  void _startPlayback() {
    if (!_pipe.isEstablished) {
      _pipe.establish();
    }
    _liveStream.start();
    _player.start();
  }

  void _stopPlayback() {
    _liveStream.stop();
    _player.stop();
  }

  void _prepareComponents() {
    _pipe = Pipe.create(widget.deviceId);
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _pipe.listen((state) {
      if (!mounted) return;
      if (state == PipeState.established) {
        setState(() => _establishFailed = false);
      } else if (state == PipeState.failed) {
        setState(() => _establishFailed = true);
      } else {
        setState(() {
          _establishFailed = false;
          _isRendering = false;
        });
      }
    });

    final streamAudioEnabled =
        DeviceAudioCapability.streamAudioEnabledFromDeviceAbilities(
            widget.deviceAbilities);
    _liveStream =
        LiveStream.createPrimary(_pipe, enableAudio: streamAudioEnabled);
    _liveStream.highQuality();

    _player = _createSamplePlayer();
    _player.onRenderState = (state) {
      if (!mounted) return;
      setState(() => _isRendering = state != RenderState.buffering);
    };

    final provider = _liveStream.provider();
    if (provider != null) {
      _player.prepare(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SampleThemeConfigure.colorVideoBackground,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Stack(
        children: [
          Center(child: _player.texture()),
          if (!_isRendering && !_establishFailed)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          if (_establishFailed)
            const Center(
              child: Icon(Icons.error_outline, color: Colors.white54, size: 32),
            ),
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.deviceName.isEmpty ? widget.deviceId : widget.deviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridLivePage extends StatefulWidget {
  const GridLivePage({super.key});

  @override
  State<GridLivePage> createState() => _GridLivePageState();
}

class _GridLivePageState extends LifecycleAwareState<GridLivePage> {
  List<Primary> _onlineDevices = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void start() {
    super.start();
    _updateVisibility();
  }

  @override
  void stop() {
    super.stop();
    for (final key in _itemKeys.values) {
      final state = key.currentState;
      if (state is _GridLiveItemWidgetState) {
        state.setVisible(false);
      }
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    final response = await SpecService.primaryByPage(0, limit: 100);

    if (!mounted) return;

    if (response.success && response.data?.list != null) {
      final allDevices = response.data!.list!;
      final deviceIds = allDevices
          .map((e) => e.deviceId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (deviceIds.isNotEmpty) {
        final statusResponse = await SpecService.onlineStatusOfList(deviceIds);

        if (!mounted) return;

        if (statusResponse.success && statusResponse.data != null) {
          _onlineDevices = allDevices.where((device) {
            final deviceId = device.deviceId ?? '';
            final status = statusResponse.data![deviceId];
            return status?.isOnline == true;
          }).toList();

          for (final device in _onlineDevices) {
            final deviceId = device.deviceId ?? '';
            if (deviceId.isNotEmpty) {
              _itemKeys[deviceId] = GlobalKey();
            }
          }
        }
      }
    }

    setState(() => _isLoading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateVisibility();
    });
  }

  void _onScroll() {
    _updateVisibility();
  }

  void _updateVisibility() {
    if (_onlineDevices.isEmpty || !_scrollController.hasClients) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportHeight = renderBox.size.height;

    for (int i = 0; i < _onlineDevices.length; i++) {
      final deviceId = _onlineDevices[i].deviceId ?? '';
      final key = _itemKeys[deviceId];

      if (key?.currentContext != null) {
        final itemRenderBox =
            key!.currentContext!.findRenderObject() as RenderBox?;
        if (itemRenderBox != null) {
          final itemPosition =
              itemRenderBox.localToGlobal(Offset.zero, ancestor: renderBox);
          final itemBottom = itemPosition.dy + itemRenderBox.size.height;

          final isVisible = itemPosition.dy < viewportHeight && itemBottom > 0;
          final state = key.currentState;
          if (state is _GridLiveItemWidgetState) {
            state.setVisible(isVisible);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SampleThemeConfigure.colorVideoBackground,
      appBar: AppBar(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Grid Live',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_onlineDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.videocam_off, size: 50, color: Colors.white54),
            SizedBox(height: 10),
            Text(
              'No online devices',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: _onlineDevices.length,
      itemBuilder: (context, index) {
        final device = _onlineDevices[index];
        final deviceId = device.deviceId ?? '';
        final deviceName = device.deviceName ?? '';

        return _GridLiveItemWidget(
          key: _itemKeys[deviceId],
          deviceId: deviceId,
          deviceName: deviceName,
          deviceAbilities: device.deviceAbilities,
        );
      },
    );
  }
}
