part of '../rapid_kit_sample_pages.dart';

class AccessPointTransportPage extends StatefulWidget {
  const AccessPointTransportPage({super.key});

  @override
  State<AccessPointTransportPage> createState() => _PageState();
}

class _PageState extends LifecycleAwareState<AccessPointTransportPage> {
  bool _finished = false;
  bool _success = false;
  String _stateTips = "";

  String _wifiSsid = "";
  String _wifiPassword = "";
  String _bindingToken = "";

  AccessPointTransport? _accessPointTransport;
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

    _accessPointTransport?.stop();
    _accessPointTransport?.destroy();

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
      _navigateToConnect();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prepareTransport() async {
    _accessPointTransport = AccessPointTransport.create();
    _accessPointTransport?.prepare(_wifiSsid, _wifiPassword, _bindingToken);
    _accessPointTransport?.listener = (state) {
      if (state.success) {
        setState(() {
          _finished = false;
          _success = false;
          _stateTips = "配网信息发送成功，\n等待设备完成联网...";
        });
        _startPollingState();
      } else {
        setState(() {
          _finished = true;
          _success = false;
          _stateTips = "配网信息发送失败！\n${state.code} ${state.message ?? "未知错误"}";
        });
      }
    };
  }

  void _prepareBindingToken() async {
    final biningTokenResp = await BindingService.token();
    if (biningTokenResp.success) {
      _bindingToken = biningTokenResp.data?.token ?? "";
    }
  }

  void _startPollingState() async {
    _bindingStatePolling?.stop();
    _bindingStatePolling = BindingStatePolling.create(_bindingToken);
    _bindingStatePolling?.listener = (resp) {
      if (resp.success) {
        setState(() {
          _finished = true;
          _success = true;
          _stateTips = "配网成功，设备ID ${resp.data}\n可以到首页修改设备名称";
        });
      } else {
        setState(() {
          _finished = true;
          _success = false;
          _stateTips = "配网失败：${resp.code} ${resp.message ?? "未知错误 "}";
        });
      }
    };
    _bindingStatePolling?.start();
  }

  Future<void> _navigateToConnect() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectAccessPointPage()),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      _prepareTransport();
      _accessPointTransport?.start();
    } else {
      Navigator.of(context).pop();
    }
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('网络配置', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          if (_finished) {
            Navigator.pop(context);
          }
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _transportStatus(),
        if (_finished) _finish(context),
      ],
    );
  }

  Padding _finish(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SampleThemeConfigure.colorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20.0),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text(
          '完成',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Expanded _transportStatus() {
    final loading = !_finished && !_success;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              loading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(SampleThemeConfigure.colorPrimary),
                    )
                  : Icon(
                      _success ? Icons.done : Icons.error,
                      size: 100,
                      color: SampleThemeConfigure.colorTextPrimary,
                    ),
              const SizedBox(height: 16),
              Text(
                _stateTips,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
