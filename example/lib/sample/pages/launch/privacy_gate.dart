// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../configure.dart';
import '../../configure/rapid_kit_sample_configure.dart';
import '../../utils/rapid_kit_sample_util.dart';

class PrivacyGate extends StatefulWidget {
  const PrivacyGate(
      {super.key, required this.background, required this.builder});

  final Widget background;
  final WidgetBuilder builder;

  @override
  State<PrivacyGate> createState() => PrivacyGateState();
}

class PrivacyGateState extends State<PrivacyGate> {
  bool _busy = true;
  bool _restoring = true;
  bool _accepted = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _restore_consent();
  }

  Future<void> _restore_consent() async {
    try {
      final privacy = await SharedPreferencesUtil.instance
          .getBool(SampleConstants.storageKeyAgreementPrivacyStatus);
      final terms = await SharedPreferencesUtil.instance
          .getBool(SampleConstants.storageKeyAgreementTermsStatus);
      if (privacy == true && terms == true) _continue_after_consent();
    } catch (_) {
      _message = '读取隐私设置失败，请重新阅读并确认。';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _restoring = false;
        });
      }
    }
  }

  Future<void> _accept_consent() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await SharedPreferencesUtil.instance
          .setBool(SampleConstants.storageKeyAgreementTermsStatus, true);
      await SharedPreferencesUtil.instance
          .setBool(SampleConstants.storageKeyAgreementPrivacyStatus, true);
      _continue_after_consent();
    } catch (_) {
      _message = '保存同意状态失败，请重试。';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continue_after_consent() {
    if (mounted) setState(() => _accepted = true);
  }

  Future<void> _open_policy(String url) async {
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Keep the gate closed if the platform has no browser integration.
    }
    if (!mounted) return;
    setState(() => _message = '无法打开协议，请在浏览器中访问：\n$url');
  }

  @override
  Widget build(BuildContext context) {
    if (_accepted) return widget.builder(context);
    return PopScope(
      canPop: false,
      child: Stack(
        key: const ValueKey('rapid-privacy-gate'),
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: ExcludeFocus(child: IgnorePointer(child: widget.background)),
          ),
          const ModalBarrier(dismissible: false, color: Colors.black54),
          if (!_restoring)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AlertDialog(
                  title: const Text('用户协议与隐私政策'),
                  scrollable: true,
                  content: _build_content(),
                  actions: [
                    TextButton(
                      key: const ValueKey('rapid-privacy-decline'),
                      onPressed: _busy ? null : () => SystemNavigator.pop(),
                      child: const Text('不同意'),
                    ),
                    ElevatedButton(
                      key: const ValueKey('rapid-privacy-accept'),
                      onPressed: _busy ? null : _accept_consent,
                      child: const Text('同意'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build_content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(TextSpan(children: [
          const TextSpan(text: '欢迎使用 TG Lab！请您阅读'),
          _policy_link('《用户协议》', RapidSampleConfigure.protocolUrl),
          const TextSpan(text: '和'),
          _policy_link('《隐私政策》', RapidSampleConfigure.privacyUrl),
          const TextSpan(
              text: '，了解相关服务及个人信息处理规则。\n\n'
                  '点击“同意”后，将初始化 RAPID 服务。在 Android 设备上，'
                  '获得定位权限后，Wi-Fi 诊断可能读取并记录网络名称（SSID）。'
                  '同意协议不代表授予系统权限。\n\n'
                  '点击“不同意”将退出应用，不会启动相关服务。'),
        ])),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!),
        ],
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  InlineSpan _policy_link(String label, String url) => WidgetSpan(
        child: Semantics(
          link: true,
          child: GestureDetector(
            onTap: () => _open_policy(url),
            child: Text(label,
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
      );
}
