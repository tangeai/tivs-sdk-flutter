part of '../rapid_kit_sample_pages.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends LifecycleAwareState<RegisterPage> {
  bool _codeSent = false;

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ensurePasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('注册新账号', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
        backgroundColor: SampleThemeConfigure.colorBackground,
      ),
      body: _buildPageBody(),
    );
  }

  Widget _buildPageBody() {
    return Container(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildAccountInput(),
              const SizedBox(height: 10),
              _buildVerificationCodeInput(),
              const SizedBox(height: 10),
              _buildPasswordInput(),
              const SizedBox(height: 10),
              _buildEnsurePasswordInput(),
              const SizedBox(height: 20),
              _buildRegisterButton(),
            ],
          ),
        ));
  }

  Widget _buildVerificationCodeInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _codeController,
              decoration: _buildInputDecoration("验证码"),
              keyboardType: TextInputType.text,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              foregroundColor: SampleThemeConfigure.colorForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            child: const Text(
              '发送验证码',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _sendVerificationCode() async {
    if (_codeSent) {
      SnackTips.show(context, "验证码已发送");
      return;
    }

    final String account = _accountController.text;
    if (account.isEmpty) {
      SnackTips.show(context, "请提供账号");
      return;
    }

    final resp = await AccountService.verificationCodeForRegister(account);
    if (!mounted) return;
    if (resp.success) {
      SnackTips.show(context, "验证码已发送");

      setState(() {
        _codeSent = true;
      });
    } else {
      SnackTips.show(context, "发送验证码失败: \n[${resp.code}] ${resp.message}");
    }
  }

  void _onRegister() async {
    final String account = _accountController.text;
    final String code = _codeController.text;
    final String password = _passwordController.text;
    final String ensurePassword = _ensurePasswordController.text;

    if (account.isEmpty) {
      SnackTips.show(context, "请提供账号");
      return;
    }

    if (code.isEmpty) {
      SnackTips.show(context, "请提供验证码");
      return;
    }

    if (password.isEmpty || ensurePassword.isEmpty) {
      SnackTips.show(context, "请提供密码");
      return;
    }

    if (password != ensurePassword) {
      SnackTips.show(context, "两次输入的密码不一致");
      return;
    }

    final resp = await AccountService.register(account, code, password);

    if (!mounted) return;

    if (!resp.success) {
      SnackTips.show(context, "注册失败: \n[${resp.code}] ${resp.message}");
      return;
    }

    await SharedPreferencesUtil.instance.setString(SampleConstants.storageKeyLoginAccount, account);

    if (!mounted) return;

    SnackTips.show(context, "注册成功");
    Navigator.pop(context);
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _onRegister,
      style: ElevatedButton.styleFrom(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        foregroundColor: SampleThemeConfigure.colorForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
      ),
      child: const Text('提交'),
    );
  }

  Widget _buildAccountInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
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
        controller: _passwordController,
        decoration: _buildInputDecoration("密码"),
        obscureText: true,
        keyboardType: TextInputType.visiblePassword,
      ),
    );
  }

  Widget _buildEnsurePasswordInput() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400.0),
      child: TextField(
        controller: _ensurePasswordController,
        decoration: _buildInputDecoration("确认密码"),
        obscureText: true,
        keyboardType: TextInputType.visiblePassword,
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
