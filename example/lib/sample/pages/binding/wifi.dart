part of '../rapid_kit_sample_pages.dart';

class WiFiPage extends StatefulWidget {
  const WiFiPage({super.key});

  @override
  State<WiFiPage> createState() => _WiFiPageState();
}

class _WiFiPageState extends LifecycleAwareState<WiFiPage> {
  String? _savedSSID;
  String? _savedPassword;

  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLocalAccount();
  }

  void _loadLocalAccount() async {
    String? localSSID = await SharedPreferencesUtil.instance.getString(SampleConstants.storageKeyWifiSSID);
    String? localPassword = await SharedPreferencesUtil.instance.getString(SampleConstants.storageKeyWifiPassword);

    if ((localSSID ?? "").isNotEmpty) {
      setState(() {
        _savedSSID = localSSID;
        _savedPassword = localPassword;
        _wifiSsidController.text = _savedSSID ?? "";
        _wifiPasswordController.text = _savedPassword ?? "";
      });
    } else {
      String currentWifiSSID = await WifiAbility.currentConnected();
      setState(() {
        _savedSSID = currentWifiSSID;
        _savedPassword = "";
        _wifiSsidController.text = _savedSSID ?? "";
        _wifiPasswordController.text = _savedPassword ?? "";
      });
    }
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
      title: const Text('选择 Wi-Fi', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
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
    return Container(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              _buildAccountInput(),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.0),
                child: Text(
                  '只支持连接 2.4GHz Wi-Fi',
                  style: TextStyle(
                    fontSize: 14,
                    color: SampleThemeConfigure.colorTextHint,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildPasswordInput(),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.0),
                child: Text(
                  'Wi-Fi 密码错误是最常见的配网失败原因之一',
                  style: TextStyle(
                    fontSize: 14,
                    color: SampleThemeConfigure.colorTextHint,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _nextStep(),
              const Spacer(),
            ],
          ),
        ));
  }

  void _onNextStepTab() async {
    final String ssid = _wifiSsidController.text;
    final String password = _wifiPasswordController.text;

    if (ssid.isEmpty) {
      SnackTips.show(context, "Provide ssid, please.");
      return;
    }

    await SharedPreferencesUtil.instance.setString(SampleConstants.storageKeyWifiSSID, ssid);
    await SharedPreferencesUtil.instance.setString(SampleConstants.storageKeyWifiPassword, password);
    if (!mounted) return;
    Navigator.pop(context, "$ssid|||$password");
  }

  Widget _nextStep() {
    return ElevatedButton(
      onPressed: _onNextStepTab,
      style: ElevatedButton.styleFrom(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        foregroundColor: SampleThemeConfigure.colorForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
      ),
      child: const Text('下一步'),
    );
  }

  Widget _buildAccountInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        controller: _wifiSsidController,
        decoration: _buildInputDecoration("输入 Wi-Fi 名称"),
        keyboardType: TextInputType.text,
      ),
    );
  }

  Widget _buildPasswordInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        controller: _wifiPasswordController,
        decoration: _buildInputDecoration("输入 Wi-Fi 密码"),
        keyboardType: TextInputType.text,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: SampleThemeConfigure.colorTextHint,
        fontSize: 16.0,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      filled: true,
      fillColor: SampleThemeConfigure.colorForeground,
      border: _buildOutlineInputBorder(),
      enabledBorder: _buildOutlineInputBorder(),
      focusedBorder: _buildOutlineInputBorder(),
    );
  }

  OutlineInputBorder _buildOutlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SampleThemeConfigure.colorPrimary, width: 1.0),
    );
  }
}
