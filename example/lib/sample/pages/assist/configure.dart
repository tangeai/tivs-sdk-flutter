part of '../rapid_kit_sample_pages.dart';

class ConfigurePage extends StatefulWidget {
  const ConfigurePage({super.key});

  @override
  State<ConfigurePage> createState() => _ConfigurePageState();
}

class _ConfigurePageState extends LifecycleAwareState<ConfigurePage> {
  final _apiEnvValue = [0, 1, 2];
  final _apiEnvName = ["正式", "预发", "测试"];

  final _switchValue = [0, 1];
  final _switchName = ["关闭", "启用"];
  final _bufferingModeValue = [0, 1, 2];
  final _bufferingModeName = ["禁用缓冲", "自动调整", "固定缓冲区"];
  final _clockModeValue = [0, 1];
  final _clockModeName = ["音频主时钟", "视频主时钟"];
  final _videoDecoderPreferenceValue = [0, 1, 2];
  final _videoDecoderPreferenceName = ["自动选择", "软件解码", "硬件解码"];

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _fixedBufferingMsController =
      TextEditingController(text: SampleConstants.fixedBufferingMs.toString());

  String _appId = "";
  String _packageName = "";
  int _apiEnv = 0;
  int _runtimeLogging = SampleConstants.switchOffValue;
  int _httpLogging = SampleConstants.switchOffValue;
  int _intercom16kSampling = SampleConstants.switchOffValue;
  int _tgrtcDebugging = SampleConstants.switchOffValue;
  int _tgrtcTcpMode = SampleConstants.switchOffValue;
  int _streamDebugging = SampleConstants.switchOffValue;
  int _pureAudioMode = SampleConstants.switchOffValue;
  int _bufferingMode = SampleConstants.bufferingMode;
  int _clockMode = SampleConstants.clockMode;
  int _videoDecoderPreference = SampleConstants.videoDecoderPreference;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: SampleThemeConfigure.colorPrimary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('应用配置',
            style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
        backgroundColor: SampleThemeConfigure.colorBackground,
        elevation: 0,
      ),
      body: _buildPageBody(),
    );
  }

  void _applyProdConfig() {
    _idController.text = SampleConstants.productionRapidAppID;
    _packageNameController.text = SampleConstants.productionRapidPackageName;
    _apiEnv = 0;
    _onSubmit();
  }

  void _applyDevConfig() {
    _idController.text = "1553153";
    _packageNameController.text = "com.tange365.icam365";
    _apiEnv = 2;
    _onSubmit();
  }

  Widget _buildPageBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _inputGroup(),
            const SizedBox(height: 16),
            _configMenuGroup(),
            if (_bufferingMode == PlayerBufferingMode.fixed.index) ...[
              const SizedBox(height: 10),
              _fixedBufferingMsInput(),
            ],
            const SizedBox(height: 20),
            _submitButton(),
            const SizedBox(height: 16),
            _quickConfigLinks(),
          ],
        ),
      ),
    );
  }

  TextStyle _primaryTextStyle() => const TextStyle(
      fontSize: 14.0,
      color: SampleThemeConfigure.colorTextPrimary,
      fontWeight: FontWeight.w700);

  TextStyle _secondaryTextStyle() =>
      const TextStyle(fontSize: 13.0, color: Color.fromRGBO(125, 123, 123, 1));

  Widget _inputGroup() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SampleThemeConfigure.colorForeground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _appIdInput(grouped: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: SampleThemeConfigure.colorTextHint.withAlpha(26),
            ),
          ),
          _packageNameInput(grouped: true),
        ],
      ),
    );
  }

  Widget _configMenuGroup() {
    final rows = <Widget>[
      _apiEnvironment(),
      _intercom16kSamplingWidget(),
      _runtimeLoggingWidget(),
      if (_runtimeLogging == SampleConstants.switchOnValue)
        _httpLoggingWidget(),
      _tgrtcDebuggingWidget(),
      _tgrtcTcpModeWidget(),
      _streamDebuggingWidget(),
      _pureAudioModeWidget(),
      _bufferingModeWidget(),
      _clockModeWidget(),
      _videoDecoderPreferenceWidget(),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SampleThemeConfigure.colorForeground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          color: SampleThemeConfigure.colorTextHint.withAlpha(26),
          tiles: rows,
        ).toList(),
      ),
    );
  }

  Widget _configRow(String title, String value, VoidCallback onTap,
      {String? subtitle}) {
    return ListTile(
      dense: true,
      minTileHeight: subtitle == null ? 44 : 54,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      title: Text(
        title,
        style: _primaryTextStyle(),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _secondaryTextStyle().copyWith(fontSize: 12, height: 1.15),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: _secondaryTextStyle(),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios,
              size: 10, color: SampleThemeConfigure.colorTextHint),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _apiEnvironment() {
    return _configRow('API 环境', _apiEnvName[_apiEnv], _onPickEnv);
  }

  Widget _intercom16kSamplingWidget() {
    return _configRow('16K 对讲采样', _switchName[_intercom16kSampling],
        _onPickIntercom16kSamplingSwitch);
  }

  Widget _runtimeLoggingWidget() {
    return _configRow(
        '控制台打印运行日志', _switchName[_runtimeLogging], _onPickLoggingSwitch);
  }

  Widget _httpLoggingWidget() {
    return _configRow(
        '控制台打印 HTTP 日志', _switchName[_httpLogging], _onPickHttpLoggingSwitch);
  }

  Widget _tgrtcDebuggingWidget() {
    return _configRow('TGRTC 调试模式', _switchName[_tgrtcDebugging],
        _onPickTgrtcDebuggingSwitch);
  }

  Widget _tgrtcTcpModeWidget() {
    return _configRow(
        'TGRTC TCP 模式', _switchName[_tgrtcTcpMode], _onPickTgrtcTcpModeSwitch);
  }

  Widget _streamDebuggingWidget() {
    return _configRow('逐帧打印音视频信息', _switchName[_streamDebugging],
        _onPickStreamDebuggingSwitch);
  }

  Widget _pureAudioModeWidget() {
    return _configRow(
      '纯音频模式',
      _switchName[_pureAudioMode],
      _onPickPureAudioModeSwitch,
      subtitle: '仅对直播场景生效，启用后播放器仅播放音频，不展示视频',
    );
  }

  Widget _bufferingModeWidget() {
    return _configRow(
        '音视频数据缓冲模式', _bufferingModeName[_bufferingMode], _onPickBufferingMode);
  }

  Widget _fixedBufferingMsInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        controller: _fixedBufferingMsController,
        decoration: _buildInputDecoration("Fixed buffer (ms)"),
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 14.0,
          color: SampleThemeConfigure.colorTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _clockModeWidget() {
    return _configRow('播放主时钟', _clockModeName[_clockMode], _onPickClockMode);
  }

  Widget _videoDecoderPreferenceWidget() {
    return _configRow(
        '视频解码',
        _videoDecoderPreferenceName[_videoDecoderPreference],
        _onPickVideoDecoderPreference);
  }

  void _onPickBufferingMode() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _bufferingModeValue.map((int mode) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_bufferingModeName[mode]),
                  onTap: () async {
                    setState(() {
                      _bufferingMode = mode;
                    });
                    await SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigBufferingMode,
                        _bufferingMode);
                    await SharedPreferencesUtil.instance.setBool(
                        SampleConstants
                            .storageKeyAppConfigBufferingModeConfigured,
                        true);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickClockMode() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _clockModeValue.map((int mode) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_clockModeName[mode]),
                  onTap: () async {
                    setState(() {
                      _clockMode = mode;
                    });
                    await SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigClockMode,
                        _clockMode);
                    await SharedPreferencesUtil.instance.setBool(
                        SampleConstants.storageKeyAppConfigClockModeConfigured,
                        true);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickVideoDecoderPreference() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _videoDecoderPreferenceValue.map((int preference) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_videoDecoderPreferenceName[preference]),
                  onTap: () async {
                    setState(() {
                      _videoDecoderPreference = preference;
                    });
                    await SharedPreferencesUtil.instance.setInt(
                        SampleConstants
                            .storageKeyAppConfigVideoDecoderPreference,
                        _videoDecoderPreference);
                    SampleConstants.applyVideoDecoderPreference(
                        _videoDecoderPreference);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickTgrtcDebuggingSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _tgrtcDebugging = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigTgrtcDebugging,
                        _tgrtcDebugging);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickTgrtcTcpModeSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _tgrtcTcpMode = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigTgrtcTcpMode,
                        _tgrtcTcpMode);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickStreamDebuggingSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _streamDebugging = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigStreamDebugging,
                        _streamDebugging);
                    RapidDiagnostics.enableStreamDebugging(
                        interval == SampleConstants.switchOnValue);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickPureAudioModeSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _pureAudioMode = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigPureAudioMode,
                        _pureAudioMode);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickLoggingSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _runtimeLogging = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigRuntimeLogging,
                        _runtimeLogging);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickHttpLoggingSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _httpLogging = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigHttpLogging,
                        _httpLogging);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickIntercom16kSamplingSwitch() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _switchValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_switchName[interval]),
                  onTap: () async {
                    setState(() {
                      _intercom16kSampling = interval;
                    });
                    SharedPreferencesUtil.instance.setInt(
                        SampleConstants.storageKeyAppConfigIntercom16kSampling,
                        _intercom16kSampling);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _onPickEnv() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: _apiEnvValue.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text(_apiEnvName[interval]),
                  onTap: () async {
                    setState(() {
                      _apiEnv = interval;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _packageNameInput({bool grouped = false}) {
    final input = TextField(
      controller: _packageNameController,
      decoration: _buildInputDecoration("包名", grouped: grouped),
      keyboardType: TextInputType.text,
      style: const TextStyle(
        fontSize: 14.0,
        color: SampleThemeConfigure.colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
    );

    if (grouped) {
      return input;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: input,
    );
  }

  void _onSubmit() async {
    if (_idController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入 APP ID')));
      return;
    }

    final fixedBufferingMs =
        int.tryParse(_fixedBufferingMsController.text.trim()) ??
            SampleConstants.fixedBufferingMs;
    if (_bufferingMode == PlayerBufferingMode.fixed.index &&
        fixedBufferingMs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fixed buffer must be greater than 0 ms')));
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final pageNavigator = Navigator.of(context);

    CenterLoading.show(context);

    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigRuntimeLogging, _runtimeLogging);
    SharedPreferencesUtil.instance
        .setInt(SampleConstants.storageKeyAppConfigHttpLogging, _httpLogging);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigIntercom16kSampling,
        _intercom16kSampling);
    SharedPreferencesUtil.instance
        .setInt(SampleConstants.storageKeyAppConfigApiEnv, _apiEnv);
    SharedPreferencesUtil.instance.setString(
        SampleConstants.storageKeyAppConfigAppId, _idController.text);
    SharedPreferencesUtil.instance.setString(
        SampleConstants.storageKeyAppConfigPackageName,
        _packageNameController.text);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigTgrtcDebugging, _tgrtcDebugging);
    SharedPreferencesUtil.instance
        .setInt(SampleConstants.storageKeyAppConfigTgrtcTcpMode, _tgrtcTcpMode);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigStreamDebugging, _streamDebugging);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigPureAudioMode, _pureAudioMode);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigBufferingMode, _bufferingMode);
    SharedPreferencesUtil.instance.setBool(
        SampleConstants.storageKeyAppConfigBufferingModeConfigured, true);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigFixedBufferingMs, fixedBufferingMs);
    SharedPreferencesUtil.instance
        .setInt(SampleConstants.storageKeyAppConfigClockMode, _clockMode);
    SharedPreferencesUtil.instance
        .setBool(SampleConstants.storageKeyAppConfigClockModeConfigured, true);
    SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAppConfigVideoDecoderPreference,
        _videoDecoderPreference);

    final ret = await RapidInitialize.init();

    if (!mounted) return;
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    if (!mounted) return;

    if (!ret) {
      messenger?.showSnackBar(const SnackBar(content: Text('重新初始化失败')));
    } else {
      SampleConstants.intercom16kSamplingEnabled =
          _intercom16kSampling == SampleConstants.switchOnValue;
      SampleConstants.pureAudioModeEnabled =
          _pureAudioMode == SampleConstants.switchOnValue;
      SampleConstants.bufferingMode = _bufferingMode;
      SampleConstants.fixedBufferingMs = fixedBufferingMs;
      SampleConstants.clockMode = _clockMode;
      Player.setDefaultBufferingMode(PlayerBufferingMode.values[_bufferingMode],
          bufferingMs: fixedBufferingMs);
      Player.setDefaultClockMode(PlayerClockMode.values[_clockMode]);
      SampleConstants.applyVideoDecoderPreference(_videoDecoderPreference);

      messenger?.showSnackBar(
        SnackBar(
            content: Text(
                'Applied: APPID=${_idController.text}, ENV=${_apiEnvName[_apiEnv]}')),
      );
      pageNavigator.pop();
    }
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: _onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        foregroundColor: SampleThemeConfigure.colorForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 12),
      ),
      child: const Text('保存并应用'),
    );
  }

  Widget _quickConfigLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _applyProdConfig,
          child: const Text(
            'Use Prod config',
            style: TextStyle(
              color: SampleThemeConfigure.colorTextHint,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: _applyDevConfig,
          child: const Text(
            'Use Dev config',
            style: TextStyle(
              color: SampleThemeConfigure.colorTextHint,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _appIdInput({bool grouped = false}) {
    final input = TextField(
      controller: _idController,
      decoration: _buildInputDecoration("APP ID", grouped: grouped),
      keyboardType: TextInputType.text,
      style: const TextStyle(
        fontSize: 14.0,
        color: SampleThemeConfigure.colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
    );

    if (grouped) {
      return input;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: input,
    );
  }

  InputDecoration _buildInputDecoration(String label, {bool grouped = false}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: SampleThemeConfigure.colorTextHint,
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      filled: true,
      fillColor:
          grouped ? Colors.transparent : SampleThemeConfigure.colorForeground,
      border: _buildOutlineInputBorder(),
      enabledBorder: _buildOutlineInputBorder(),
      focusedBorder: _buildOutlineInputBorder(),
    );
  }

  OutlineInputBorder _buildOutlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
    );
  }

  void _loadCurrentConfig() async {
    String? localAppId = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyAppConfigAppId);
    String? localPackageName = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyAppConfigPackageName);
    int? localApiEnv = await SharedPreferencesUtil.instance
        .getInt(SampleConstants.storageKeyAppConfigApiEnv);

    int localIntercom16kSampling = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigIntercom16kSampling) ??
        SampleConstants.switchOffValue;

    int localRuntimeLogging = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigRuntimeLogging) ??
        SampleConstants.switchOffValue;

    int localHttpLogging = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigHttpLogging) ??
        SampleConstants.switchOffValue;

    int localTgrtcDebugging = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigTgrtcDebugging) ??
        SampleConstants.switchOffValue;

    int localTgrtcTcpMode = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigTgrtcTcpMode) ??
        SampleConstants.switchOffValue;

    int localStreamDebugging = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigStreamDebugging) ??
        SampleConstants.switchOffValue;

    int localPureAudioMode = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigPureAudioMode) ??
        SampleConstants.switchOffValue;

    bool localBufferingModeConfigured = await SharedPreferencesUtil.instance
            .getBool(
                SampleConstants.storageKeyAppConfigBufferingModeConfigured) ??
        false;
    int localBufferingMode = localBufferingModeConfigured
        ? await SharedPreferencesUtil.instance
                .getInt(SampleConstants.storageKeyAppConfigBufferingMode) ??
            SampleConstants.bufferingMode
        : SampleConstants.bufferingMode;
    if (localBufferingMode < 0 ||
        localBufferingMode >= PlayerBufferingMode.values.length) {
      localBufferingMode = SampleConstants.bufferingMode;
    }

    int localFixedBufferingMs = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigFixedBufferingMs) ??
        SampleConstants.fixedBufferingMs;
    if (localFixedBufferingMs <= 0) {
      localFixedBufferingMs = SampleConstants.fixedBufferingMs;
    }

    bool localClockModeConfigured = await SharedPreferencesUtil.instance
            .getBool(SampleConstants.storageKeyAppConfigClockModeConfigured) ??
        false;
    int localClockMode = localClockModeConfigured
        ? await SharedPreferencesUtil.instance
                .getInt(SampleConstants.storageKeyAppConfigClockMode) ??
            SampleConstants.clockMode
        : SampleConstants.clockMode;
    if (localClockMode < 0 || localClockMode >= PlayerClockMode.values.length) {
      localClockMode = SampleConstants.clockMode;
    }

    int localVideoDecoderPreference = await SharedPreferencesUtil.instance
            .getInt(
                SampleConstants.storageKeyAppConfigVideoDecoderPreference) ??
        SampleConstants.videoDecoderPreference;
    localVideoDecoderPreference = SampleConstants.resolveVideoDecoderPreference(
        localVideoDecoderPreference);

    if (localAppId?.isNotEmpty == true) {
      _appId = localAppId!;
    } else {
      _appId = SampleConstants.defaultRapidAppID;
    }

    if (localPackageName?.isNotEmpty == true) {
      _packageName = localPackageName!;
    } else {
      _packageName = SampleConstants.defaultRapidPackageName;
    }

    if (localApiEnv != null) {
      _apiEnv = localApiEnv;
    }

    setState(() {
      _appId = _appId;
      _packageName = _packageName;
      _apiEnv = _apiEnv;
      _intercom16kSampling = localIntercom16kSampling;
      _runtimeLogging = localRuntimeLogging;
      _httpLogging = localHttpLogging;
      _tgrtcDebugging = localTgrtcDebugging;
      _tgrtcTcpMode = localTgrtcTcpMode;
      _streamDebugging = localStreamDebugging;
      _pureAudioMode = localPureAudioMode;
      _bufferingMode = localBufferingMode;
      _clockMode = localClockMode;
      _videoDecoderPreference = localVideoDecoderPreference;
      _idController.text = _appId;
      _packageNameController.text = _packageName;
      _fixedBufferingMsController.text = localFixedBufferingMs.toString();
    });
  }
}
