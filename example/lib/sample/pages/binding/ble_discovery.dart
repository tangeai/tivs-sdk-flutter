part of '../rapid_kit_sample_pages.dart';

class BleDiscoveryPage extends StatefulWidget {
  const BleDiscoveryPage({super.key});

  @override
  State<BleDiscoveryPage> createState() => _BleDiscoveryState();
}

// We use a custom filter to only show devices with name starting with "AICAM_"
class SampleBleDeviceFilter implements BleDeviceFilter {
  @override
  bool accept(String name) => name.startsWith("AICAM_");
}

class _BleDiscoveryState extends LifecycleAwareState<BleDiscoveryPage> {
  final List<BleDevice> _devices = [];
  final BleDiscovery _bleDiscovery = BleDiscovery();

  bool _isTimeout = false;

  @override
  void initState() {
    super.initState();
    _discovery();
  }

  @override
  void dispose() {
    super.dispose();
    _bleDiscovery.stop();
  }

  void _discovery() {
    _bleDiscovery.filter = SampleBleDeviceFilter();
    _bleDiscovery.onTimeout = () {
      setState(() {
        _isTimeout = true;
      });
    };

    _bleDiscovery.onRefresh = (devices) {
      setState(() {
        _devices.clear();
        _devices.addAll(devices);
      });
    };

    _bleDiscovery.start();
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
    return _devices.isEmpty ? _buildLoadingIndicator() : _buildDeviceList();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(SampleThemeConfigure.colorPrimary),
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
          onTap: () => _onSelectDevice(device.id),
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
                  child: Text(device.name, style: const TextStyle(fontSize: 14.0)),
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
