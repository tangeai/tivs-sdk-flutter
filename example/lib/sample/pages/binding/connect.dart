part of '../rapid_kit_sample_pages.dart';

class ConnectAccessPointPage extends StatefulWidget {
  const ConnectAccessPointPage({super.key});

  @override
  State<ConnectAccessPointPage> createState() => _ConnectAccessPointPageState();
}

class _ConnectAccessPointPageState extends LifecycleAwareState<ConnectAccessPointPage> {
  static const String _accessPointPrefix = "AICAM_";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('连接到设备热点', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context, false);
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '智能摄像头',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SampleThemeConfigure.colorTextPrimary),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '请将手机 Wi-Fi 连接到 "${_accessPointPrefix}xxxx" 后，返回APP',
            style: TextStyle(
              fontSize: 16,
              color: SampleThemeConfigure.colorTextSub,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              color: const Color.fromRGBO(97, 94, 94, 0.138),
              child: const Center(
                child: Icon(
                  Icons.settings,
                  size: 100,
                  color: SampleThemeConfigure.colorTextPrimary,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20.0),
            ),
            onPressed: () async {
              final ret = await WifiAbility.launchSetting();
              if (!mounted) return;
              if (!ret) SnackTips.show(context, "打开系统设置页失败");
            },
            child: const Text(
              '去设置页连接',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 5, 118, 76),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20.0),
            ),
            onPressed: () async {
              final currentWifi = await WifiAbility.currentConnected();
              if (!mounted) return;
              if (currentWifi.isEmpty || currentWifi.startsWith(_accessPointPrefix)) {
                Navigator.pop(context, true);
              } else {
                SnackTips.show(context, "你需要先手动连接到设备热点（$_accessPointPrefix 开头），\n当前连接的 Wi-Fi 是 $currentWifi");
              }
            },
            child: const Text(
              '确认已连接，下一步',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
