// ignore_for_file: non_constant_identifier_names
part of '../rapid_kit_sample_pages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.privacy_preview = false,
    this.initialDebuggingCode,
    this.initialTargetDeviceId,
  });

  final String? initialDebuggingCode;
  final bool privacy_preview;
  final String? initialTargetDeviceId;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends LifecycleAwareState<LoginPage> {
  @override
  bool get lifecycle_enabled => !widget.privacy_preview;

  String? _savedAccessToken;
  String? _savedAccount;
  bool _initialDebuggingCodeApplied = false;

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.privacy_preview) return;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocalAccount());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _applyInitialDebuggingCode());
  }

  void _loadLocalAccount() async {
    String? account = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyLoginAccount);
    if (account == null || account.isEmpty) return;
    setState(() {
      _savedAccount = account;
      _accountController.text = _savedAccount ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const ValueKey('rapid-login-page-root'),
        resizeToAvoidBottomInset: false,
        body: PlatformUtil.autoUnfocus(child: _page()),
      ),
    );
  }

  Stack _page() {
    return Stack(
      children: [
        _buildPageBody(),
        _buildRegister(),
        _buildConfigure(),
        Positioned(
          top: 110,
          left: 20,
          child: TextButton(
            key: const ValueKey('connection-page-open'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionPage())),
            child: const Text('Connection check'),
          ),
        ),
        _buildDebugButton()
      ],
    );
  }

  Positioned _buildRegister() {
    return Positioned(
      top: 80,
      right: 20,
      child: GestureDetector(
        onTap: _onRegister,
        child: const Text(
          '注册新账号',
          style: TextStyle(
            color: Color.fromARGB(255, 175, 173, 173),
            decoration: TextDecoration.underline,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Positioned _buildConfigure() {
    return Positioned(
      top: 80,
      left: 20,
      child: GestureDetector(
        onTap: () {
          _launchConfigure();
        },
        child: const Text(
          '应用配置',
          style: TextStyle(
            color: Color.fromARGB(255, 175, 173, 173),
            decoration: TextDecoration.underline,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPageBody() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Stack(
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 100),
                _buildTitle(),
                const SizedBox(height: 20),
                _buildVersionText(),
                const SizedBox(height: 60),
                _buildAccountInput(),
                const SizedBox(height: 10),
                _buildPasswordInput(),
                const SizedBox(height: 5),
                _buildForgotPassword(),
                const SizedBox(height: 20),
                _buildLoginButton(),
                _buildTokenLogin(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void _onLogin() async {
    FocusScope.of(context).unfocus();
    final String account = _accountController.text;
    final String password = _passwordController.text;
    if (account.isEmpty || password.isEmpty) return;

    CenterLoading.show(context);

    final loginResp = await AccountService.login(account, password);
    if (!mounted) return;
    if (!loginResp.success) {
      CenterLoading.hide(context);
      context.showSnackDialog(
        title: "噢，登录出错了",
        content: "错误码：${loginResp.code} \n信息：${loginResp.message}",
        onConfirm: () {},
        onCancel: () {},
      );

      return;
    }

    final authRet = await _onAccessTokenAuth(loginResp.data?.accessToken);
    if (!mounted) return;
    CenterLoading.hide(context);

    if (authRet) {
      SharedPreferencesUtil.instance
          .setString(SampleConstants.storageKeyLoginAccount, account);
      _launchHomePage();
    }
  }

  void _launchHomePage() {
    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomePage(initialTargetDeviceId: widget.initialTargetDeviceId)));
  }

  Future<bool> _onAccessTokenAuth(String? accessToken) async {
    final authResp = await Authenticate.configure(accessToken ?? "");

    if (!mounted) return false;

    if (!authResp.success) {
      SnackTips.show(context,
          "Failed to authenticate: \n[${authResp.code}] ${authResp.message}");
      CenterLoading.hide(context);
      return false;
    } else {
      SharedPreferencesUtil.instance
          .setString(SampleConstants.storageKeyLoginToken, accessToken ?? "");
      PushNotificationCoordinator.instance.handleAuthenticationSucceeded();
    }

    if (!mounted) return false;
    return true;
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _onLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        foregroundColor: SampleThemeConfigure.colorForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: const Text('登录'),
    );
  }

  Widget _buildVersionText() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Center(
        child: Text(
          widget.privacy_preview
              ? 'Based on TiRTC Flutter SDK'
              : 'Based on TiRTC Flutter SDK\nv${RapidKit.versionName}, ${RapidKit.commitHash}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color.fromARGB(159, 179, 179, 179),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildTokenLogin() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: GestureDetector(
          onTap: _onTokenLogin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '或者，识别剪贴板的令牌',
                style: TextStyle(
                  color: SampleThemeConfigure.colorPrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                height: 1,
                width: 130,
                color: SampleThemeConfigure.colorPrimary.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Text(
        '\u6b22\u8fce\u4f7f\u7528 TG Flutter',
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: SampleThemeConfigure.colorPrimary,
        ),
      ),
    );
  }

  void _launchConfigure() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigurePage()),
    );
  }

  TextStyle _buildTextStyle() {
    return const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: SampleThemeConfigure.colorPrimary,
    );
  }

  Widget _buildAccountInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        style: _buildTextStyle(),
        controller: _accountController,
        decoration: _buildInputDecoration("手机号或邮箱"),
        keyboardType: TextInputType.text,
      ),
    );
  }

  Widget _buildPasswordInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        style: _buildTextStyle(),
        controller: _passwordController,
        decoration: _buildInputDecoration("密码"),
        obscureText: true,
        keyboardType: TextInputType.visiblePassword,
      ),
    );
  }

  Widget _buildForgotPassword() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForgetPage()),
            );
          },
          child: const Text(
            '忘记密码',
            style: TextStyle(
              color: SampleThemeConfigure.colorTextHint,
              decoration: TextDecoration.underline,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: SampleThemeConfigure.colorTextHint,
          fontSize: 14.0,
          fontWeight: FontWeight.bold),
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
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
    );
  }

  Positioned _buildDebugButton() {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    final IconData iconData =
        isMobile ? Icons.qr_code_rounded : Icons.content_paste_rounded;
    final String buttonText = isMobile ? '扫描调试二维码' : '识别剪贴板的调试二维码';

    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          key: const ValueKey('rapid-login-debugging-code-action'),
          onTap: () async => _onAcceptDebuggingCode(context),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: SampleThemeConfigure.colorTextSub,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(iconData, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 6),
              Text(
                buttonText,
                style: const TextStyle(
                    color: SampleThemeConfigure.colorTextSub, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAcceptDebuggingCode(BuildContext context) async {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    String? resultText;

    if (isMobile) {
      resultText = await _readMobileDebuggingCode(context);
      if (!context.mounted || resultText == null) return;
    } else {
      ClipboardData? clipboardData = await Clipboard.getData('text/plain');
      if (!context.mounted) return;
      resultText = clipboardData?.text ?? '';
      if (resultText.isEmpty) {
        SnackTips.show(context, '剪切板为空');
        return;
      }
    }

    final ret = Assistant.applyDebuggingCode(resultText);
    if (!ret) {
      SnackTips.show(context, '无效的调试码，通常是用户令牌过期，请重新获取。');
    } else {
      PushNotificationCoordinator.instance.handleAuthenticationSucceeded();
      if (isMobile) {
        await SharedPreferencesUtil.instance.setString(
          SampleConstants.storageKeyLoginDebuggingCode,
          resultText,
        );
      }
      SnackTips.show(context, '调试码识别成功，准备跳转首页');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _launchHomePage();
    }
  }

  Future<void> _applyInitialDebuggingCode() async {
    if (_initialDebuggingCodeApplied) {
      return;
    }
    _initialDebuggingCodeApplied = true;
    final code = widget.initialDebuggingCode;
    if (code == null || code.isEmpty) {
      return;
    }

    final ret = Assistant.applyDebuggingCode(code);
    if (!ret) {
      if (mounted) {
        SnackTips.show(context, 'Invalid debugging code.');
      }
      return;
    }

    PushNotificationCoordinator.instance.handleAuthenticationSucceeded();
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    if (isMobile) {
      await SharedPreferencesUtil.instance.setString(
        SampleConstants.storageKeyLoginDebuggingCode,
        code,
      );
    }
    if (!mounted) return;
    _launchHomePage();
  }

  Future<String?> _readMobileDebuggingCode(BuildContext context) async {
    final lastDebuggingCode = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyLoginDebuggingCode);
    if (!context.mounted) return null;

    if (lastDebuggingCode != null && lastDebuggingCode.isNotEmpty) {
      final useLast = await _showUseLastDebuggingCodeDialog(context);
      if (!context.mounted) return null;
      if (useLast) return lastDebuggingCode;
    }

    final resultText = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (!context.mounted) return null;
    if (resultText == null || resultText.isEmpty) {
      SnackTips.show(context, '扫描取消或无效');
      return null;
    }
    return resultText;
  }

  Future<bool> _showUseLastDebuggingCodeDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('识别调试二维码'),
          content: const Text('是否使用上一次的调试二维码？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('否，我要重新扫'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('是'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _onTokenLogin() async {
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (!mounted) return;
    final clipboardText = clipboardData?.text ?? '';
    if (clipboardText.isEmpty) {
      SnackTips.show(context, '剪切板为空');
      return;
    }

    CenterLoading.show(context);
    final authRet = await _onAccessTokenAuth(clipboardText);
    if (!mounted) return;
    CenterLoading.hide(context);

    if (authRet) {
      SharedPreferencesUtil.instance
          .setString(SampleConstants.storageKeyLoginAccount, '');
      _launchHomePage();
    }
  }

  @override
  void start() {
    super.start();
    // delay for status bar to take effect
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Platform.isAndroid) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ));
      } else if (Platform.isIOS) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ));
        // Force rebuild to apply AnnotatedRegion
        if (mounted) {
          setState(() {});
        }
      }
    });
  }
}
