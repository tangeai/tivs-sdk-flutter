part of '../rapid_kit_sample_pages.dart';

class LanDiscoveryPage extends StatefulWidget {
  const LanDiscoveryPage({super.key});

  @override
  State<LanDiscoveryPage> createState() => _LanDiscoveryState();
}

class _LanDiscoveryState extends LifecycleAwareState<LanDiscoveryPage> {
  final List<String> _devices = [];
  final LanDiscovery _lanDiscovery = LanDiscovery();

  bool _isTimeout = false;

  @override
  void initState() {
    super.initState();
    _discovery();
  }

  @override
  void start() {
    super.start();
    _isTimeout = false;
    _devices.clear();
    setState(() {
      _isTimeout = false;
    });
    _lanDiscovery.start();
  }

  @override
  void stop() {
    super.stop();
    _lanDiscovery.stop();
  }

  void _discovery() {
    _lanDiscovery.onTimeout = () {
      setState(() {
        _isTimeout = true;
      });
    };

    _lanDiscovery.onRefresh = (devices) {
      setState(() {
        _devices.clear();
        _devices.addAll(devices);
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildPageBody(),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('选择设备', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context, "");
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildPageBody() {
    if (_isTimeout) {
      return _buildTimeoutTips();
    }

    return _devices.isEmpty ? _buildLoadingIndicator() : _buildDeviceList();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(SampleThemeConfigure.colorPrimary),
      ),
    );
  }

  Widget _buildTimeoutTips() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline_rounded, color: SampleThemeConfigure.colorPrimary, size: 48),
          SizedBox(height: 16.0),
          Text('未发现设备', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return GestureDetector(
          onTap: () => _onSelectDevice(device),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_outdoor_rounded, color: SampleThemeConfigure.colorPrimary),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(device, style: const TextStyle(fontSize: 14.0)),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: SampleThemeConfigure.colorTextHint,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSelectDevice(String id) async {
    Navigator.pop(context, id);
  }
}
