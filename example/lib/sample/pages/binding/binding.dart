part of '../rapid_kit_sample_pages.dart';

class BindingPage extends StatefulWidget {
  const BindingPage({super.key});

  @override
  State<BindingPage> createState() => _BindingPageState();
}

class _BindingPageState extends LifecycleAwareState<BindingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('添加设备', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    if (Platform.isWindows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[_qrcodeBinding(), _directlyBinding()],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[_bluetoothBinding(), _accessPointBinding(), _qrcodeBinding(), _directlyBinding(), _wiredLanBinding()],
    );
  }

  GestureDetector _wiredLanBinding() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LanBindingPage()));
      },
      child: _buildRoundedRectangleWithIconAndText(icon: Icons.linear_scale_rounded, text: "有线添加"),
    );
  }

  GestureDetector _directlyBinding() {
    return GestureDetector(
      onTap: () async => _onDirectlyBinding(),
      child: _buildRoundedRectangleWithIconAndText(icon: Icons.insert_link_rounded, text: "直接绑定"),
    );
  }

  void _onDirectlyBinding() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('绑定设备'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '设备ID',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: const Text('设备ID不能为空'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  final response = await BindingService.bind(controller.text, deviceName: "书房摄像头");
                  if (!mounted) return;
                  if (!response.success) {
                    SnackTips.show(context, "Error: ${response.message}");
                  } else {
                    SnackTips.show(context, "绑定成功");
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  GestureDetector _qrcodeBinding() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BindingByQrcodePage()));
      },
      child: _buildRoundedRectangleWithIconAndText(icon: Icons.qr_code, text: "设备扫码"),
    );
  }

  GestureDetector _bluetoothBinding() {
    return GestureDetector(
      onTap: () async => _onBluetoothTap(),
      child: _buildRoundedRectangleWithIconAndText(icon: Icons.bluetooth_audio_outlined, text: "蓝牙配网"),
    );
  }

  GestureDetector _accessPointBinding() {
    return GestureDetector(
      onTap: () async => _onAccessPointTap(),
      child: _buildRoundedRectangleWithIconAndText(icon: Icons.wifi_tethering, text: "热点配网"),
    );
  }

  void _onBluetoothTap() async {
    // 注意：iOS需要先得到蓝牙权限，然后才能检查蓝牙是否开启
    bool granted = await RuntimePermissions.accessGranted(PermissionType.bluetooth);
    if (!mounted) return;
    if (!granted) {
      final ret = await RuntimePermissions.requestAccess(PermissionType.bluetooth);
      if (ret == PermissionState.denied) {
        SnackTips.show(context, "你需要到系统设置中打开蓝牙权限");
        return;
      }
    }

    final bleEnabled = await BleAbility.enabled();
    if (!mounted) return;
    if (!bleEnabled) {
      SnackTips.show(context, "请打开蓝牙后，再次点击");
      return;
    }

    bool locationPermissionGranted = await RuntimePermissions.accessGranted(PermissionType.location);
    if (!mounted) return;
    if (!locationPermissionGranted) {
      final ret = await RuntimePermissions.requestAccess(PermissionType.location);
      if (ret == PermissionState.denied) {
        SnackTips.show(context, "你需要到系统设置中打开位置权限");
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const BleTransportPage()));
  }

  void _onAccessPointTap() async {
    bool locationPermissionGranted = await RuntimePermissions.accessGranted(PermissionType.location);
    if (!mounted) return;
    if (!locationPermissionGranted) {
      final ret = await RuntimePermissions.requestAccess(PermissionType.location);
      if (ret == PermissionState.denied) {
        SnackTips.show(context, "你需要到系统设置中打开位置权限");
        return;
      }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AccessPointTransportPage()));
  }

  void _onPerformUpgrade() async {
    final resp = await chooseWifi(context);
    if (!mounted) return;
    SnackTips.show(context, resp.ssid);
  }

  Widget _buildRoundedRectangleWithIconAndText(
      {required IconData icon, required String text, Color textColor = SampleThemeConfigure.colorTextPrimary}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: SampleThemeConfigure.colorPrimary),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: SampleThemeConfigure.colorPrimary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
