part of '../rapid_kit_sample_pages.dart';

class BindingByQrcodePage extends StatefulWidget {
  const BindingByQrcodePage({super.key});

  @override
  State<BindingByQrcodePage> createState() => _BindingByQrcodePageState();
}

class _BindingByQrcodePageState extends LifecycleAwareState<BindingByQrcodePage> {
  bool _loading = false;
  bool _heard = false;

  String _wifiSsid = "";
  String _wifiPassword = "";
  String _bindingToken = "";

  String _bindingProfile = "";

  BindingStatePolling? _bindingStatePolling;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToReset();
    });
  }

  @override
  void dispose() {
    super.dispose();

    _bindingStatePolling?.stop();
  }

  Future<void> _navigateToReset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPage()),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      _navigateToWifi();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _navigateToWifi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WiFiPage()),
    );

    if (!mounted) {
      return;
    }

    if (result.isNotEmpty) {
      List<String> parts = result.split('|||');
      _wifiSsid = parts.isNotEmpty ? parts[0] : '';
      _wifiPassword = parts.length > 1 ? parts[1] : '';

      _prepareBindingToken();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prepareBindingToken() async {
    final biningTokenResp = await BindingService.token();
    if (!mounted) return;
    if (biningTokenResp.success) {
      _bindingToken = biningTokenResp.data?.token ?? "";
      _bindingProfile = BindingService.profile(_wifiSsid, _wifiPassword, _bindingToken);

      setState(() {
        _bindingProfile = _bindingProfile;
      });
    } else {
      SnackTips.show(context, "无法获取绑定令牌：[${biningTokenResp.code}] ${biningTokenResp.message}");
      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.of(context).pop();
      });
    }
  }

  void _startPollingState() async {
    _bindingStatePolling?.stop();
    _bindingStatePolling = BindingStatePolling.create(_bindingToken);
    _bindingStatePolling?.listener = (resp) {
      String stateTips = "";
      if (resp.success) {
        stateTips = "配网成功，设备ID ${resp.data}\n可以到首页修改设备名称";
        _updateDeviceName(resp.data ?? "");
        setState(() {
          _loading = false;
        });
      } else {
        stateTips = "配网失败：${resp.code} ${resp.message ?? "未知错误 "}";
        setState(() {
          _loading = false;
        });
      }

      _showResult(stateTips);
    };
    _bindingStatePolling?.start();
  }

  void _updateDeviceName(String deviceId) async {
    await SpecService.rename(deviceId, "客厅摄像头");
  }

  Future<void> _showResult(String tips) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 设置为false，点击对话框外部无法关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(tips),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('我知道了'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('二维码配网', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '向设备的摄像头展示二维码，距离10-30厘米。',
            style: TextStyle(
              fontSize: 14,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _qrcode(),
                  ],
                ),
              ),
              if (_loading)
                Center(
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              if (_loading)
                Center(
                  child: createCenterLoading(size: 20, color: Colors.white),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Checkbox(
                value: _heard,
                activeColor: SampleThemeConfigure.colorPrimary,
                onChanged: (bool? value) {
                  setState(() {
                    if (_loading) return;
                    _heard = value!;
                  });
                },
              ),
              const Text('我已听到设备发出的提示音', style: TextStyle(color: SampleThemeConfigure.colorTextPrimary, fontSize: 14)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: (_heard && !_loading) ? _onNextStepTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              foregroundColor: SampleThemeConfigure.colorForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
            ),
            child: Text(_loading ? '绑定中...' : '下一步'),
          ),
        ),
      ],
    );
  }

  void _onNextStepTap() {
    if (_loading) return;

    if (_heard) {
      _startPollingState();
      setState(() {
        _loading = true;
      });
    } else {
      SnackTips.show(context, "确认听到设备发出的提示音，再点击");
    }
  }

  Widget _qrcode() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: BindingService.qrcode(_bindingProfile, size: constraints.maxWidth * 0.9),
          ),
        );
      }),
    );
  }
}
