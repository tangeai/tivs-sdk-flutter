part of '../rapid_kit_sample_pages.dart';

class InstructChannelPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  const InstructChannelPage({super.key, required this.deviceId, required this.deviceName});

  @override
  State<InstructChannelPage> createState() => _InstructChannelPageState();
}

class _InstructChannelPageState extends LifecycleAwareState<InstructChannelPage> {
  static const int _dataTypeText = 0;
  static const int _dataTypeHex = 1;

  static const String _hintDataTypeText = "输入参数\n任意文本格式\n如 {\"key\":\"value\"}";
  static const String _hintDataTypeHex = "输入参数\n每两个十六进制字符代表一个字节\n不需要空格\n如 AABBCC";
  static const List<String> _dataTypeHints = [_hintDataTypeText, _hintDataTypeHex];

  late String _deviceId;
  late String _deviceName;

  late Pipe _pipe;

  bool _connected = false;
  bool _failed = false;

  String? _savedId;
  String? _savedData;

  int _selectedDataType = _dataTypeHex;

  Resp<Uint8List?>? _instructResponse;

  final TextEditingController _instructIdController = TextEditingController();
  final TextEditingController _instructDataController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;

    WidgetsBinding.instance.addObserver(this);

    _preparePipe();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pipe.establish();
    });
  }

  @override
  void dispose() {
    super.dispose();

    _pipe.abolish();
    _pipe.destroy();

    WidgetsBinding.instance.removeObserver(this);
  }

  void _preparePipe() {
    _pipe = Pipe.create(_deviceId);
    // IMPORTANT: Only use TCP mode (1) when remote device explicitly supports it and there is a clear requirement
    _pipe.setTransportMode(SampleConstants.tgrtcTcpModeEnabled ? 1 : 0);
    _pipe.listen((state) {
      setState(() {
        _failed = state == PipeState.failed;
        _connected = state == PipeState.established;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLocalAccount();
  }

  void _loadLocalAccount() async {
    String? localId = await SharedPreferencesUtil.instance.getString(SampleConstants.storageKeyInstructionId);
    String? localData = await SharedPreferencesUtil.instance.getString(SampleConstants.storageKeyInstructionData);

    if ((localId ?? "").isNotEmpty) {
      setState(() {
        _savedId = localId;
        _savedData = localData;
        _instructIdController.text = _savedId ?? "";
        _instructDataController.text = _savedData ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: Container(
        child: _failed ? _retry() : (!_connected ? createCenterLoading(size: 20.0) : _buildPageBody()),
      ),
    );
  }

  Widget _retry() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _pipe.establish();
        },
        child: const Text("点击重试", style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      ),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text("自定义指令", style: TextStyle(color: SampleThemeConfigure.colorPrimary, fontSize: 16)),
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
    String response = _formatResponse();

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            "${_deviceName.isNotEmpty ? "$_deviceName " : " "}($_deviceId)",
            style: const TextStyle(fontSize: 14, color: SampleThemeConfigure.colorPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildInstructIdInput(),
          const SizedBox(height: 20),
          _buildInstructDataInput(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildRadioOption(0, '文本'),
              const SizedBox(width: 10),
              _buildRadioOption(1, '十六进制'),
            ],
          ),
          const SizedBox(height: 30),
          _nextStep(),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  // Added
                  child: Text(
                    response,
                    style: TextStyle(fontSize: 14, color: SampleThemeConfigure.colorTextPrimary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _formatResponse() {
    String response = "";
    if (_instructResponse != null) {
      if (_instructResponse!.success) {
        response = "请求成功！\n\n";

        if (_instructResponse!.data != null) {
          response += "字节数据：\n[";
          response += _instructResponse!.data!.join(",");
          response += "]";

          try {
            response += "\n\nUTF-8字符串：\n${utf8.decode(_instructResponse!.data!)}";
          } catch (e) {
            response += "\n\n无法转换😑";
          }
        }
      } else {
        response = "请求失败，错误码 ${_instructResponse!.code} ${_instructResponse!.message}";
      }
    }
    return response;
  }

  Widget _buildRadioOption(int value, String label) {
    return Row(
      children: <Widget>[
        Radio<int>(
          value: value,
          groupValue: _selectedDataType,
          activeColor: SampleThemeConfigure.colorPrimary,
          fillColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) =>
                states.contains(MaterialState.selected) ? SampleThemeConfigure.colorPrimary : SampleThemeConfigure.colorTextHint,
          ),
          onChanged: (int? newValue) {
            setState(() => _selectedDataType = newValue ?? 0);
          },
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: SampleThemeConfigure.colorTextHint)),
      ],
    );
  }

  void _onNextStepTab() async {
    FocusScope.of(context).unfocus();

    String id = _instructIdController.text;
    final String data = _instructDataController.text;

    if (id.isEmpty) {
      SnackTips.show(context, "输入指令ID");
      return;
    }

    if (id.startsWith("0x") || id.startsWith("0X")) {
      id = id.substring(2);
    }

    SharedPreferencesUtil.instance.setString(SampleConstants.storageKeyInstructionId, id);
    SharedPreferencesUtil.instance.setString(SampleConstants.storageKeyInstructionData, data);

    final instructId = int.parse(id, radix: 16);
    Uint8List? instructData = _convertData(data);

    final resp = await _pipe.instruct(instructId, instructData);
    setState(() => _instructResponse = resp);
  }

  Uint8List? _convertData(String? data) {
    if (data == null || data.isEmpty) {
      return null;
    }

    switch (_selectedDataType) {
      case _dataTypeText:
        return Uint8List.fromList(utf8.encode(data));
      case _dataTypeHex:
        return _convertHexData(data);
      default:
        return null;
    }
  }

  Uint8List _convertBinaryData(String data) {
    final int length = data.length;
    final int size = length ~/ 8 + (length % 8 == 0 ? 0 : 1);
    final Uint8List buffer = Uint8List(size);

    for (int i = 0; i < size; i++) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        final int index = i * 8 + j;
        if (index < length) {
          final int bit = data.codeUnitAt(index) - 48;
          byte |= bit << (7 - j);
        }
      }
      buffer[i] = byte;
    }

    return buffer;
  }

  Uint8List _convertHexData(String data) {
    final int length = data.length;
    final int size = length ~/ 2 + (length % 2 == 0 ? 0 : 1);
    final Uint8List buffer = Uint8List(size);

    for (int i = 0; i < size; i++) {
      int byte = 0;
      for (int j = 0; j < 2; j++) {
        final int index = i * 2 + j;
        if (index < length) {
          final int hex = data.codeUnitAt(index);
          byte |= _hexToByte(hex) << (4 * (1 - j));
        }
      }
      buffer[i] = byte;
    }

    return buffer;
  }

  int _hexToByte(int hex) {
    if (hex >= 48 && hex <= 57) {
      return hex - 48;
    } else if (hex >= 65 && hex <= 70) {
      return hex - 55;
    } else if (hex >= 97 && hex <= 102) {
      return hex - 87;
    } else {
      return 0;
    }
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
      child: const Text('发送指令'),
    );
  }

  Widget _buildInstructIdInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        controller: _instructIdController,
        decoration: _buildInputDecoration("指令ID（十六进制格式，如 0372"),
        keyboardType: TextInputType.text,
      ),
    );
  }

  Widget _buildInstructDataInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        controller: _instructDataController,
        decoration: _buildInputDecoration(_dataTypeHints[_selectedDataType]),
        keyboardType: TextInputType.text,
        maxLines: 4,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: SampleThemeConfigure.colorTextHint,
        fontSize: 14.0,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
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
