part of '../library.dart';

class _AssistantDialog {
  static const _dialogBackgroundColor = Color(0xFFFFF8E8);
  static const _dialogTitleColor = Color(0xFF659287);
  static const _dialogTextColor = Color(0xFF666666);

  static const _assistantTerms = '''
为了更高效地解决您遇到的问题或技术故障，我们需要远程连接到您的摄像头进行调试。而进行此操作需要您的明确授权，因为安全机制确保了只有设备的主人才能够访问设备、或者通过授权的方式允许其他人访问设备。

以下是关于调试授权的详细说明：
1. 目的：远程调试可帮助我们及时定位问题，但这需要您通过生成并提供一个临时二维码来授权。
2. 访问权限：您通过生成的二维码临时分享的登录令牌，是开发人员获得调试所需访问权限的唯一方式。
3. 隐私预防：在授权前，请考虑调整摄像头角度或关闭摄像头音频。
4. 二维码有效期：仅在您当前登录会话期间有效。当你主动注销登录、或会话过期后，二维码将自动失效。

此外，还可能需要您上传日志以帮助诊断问题：
1. 日志包含程序的运行状态，将仅用于问题分析。
2. 上传过程通过加密连接进行，确保传输安全性。
3. 云端数据严格保密，并定期清理。
''';

  _AssistantDialog._();

  static Text subEntryText(String text) =>
      Text(text, style: const TextStyle(color: _dialogTextColor, fontSize: 14));

  static ListTile entry(String text, void Function() onTap, IconData icon,
          {Key? key}) =>
      ListTile(
        key: key,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.white,
        leading: Icon(icon, color: _dialogTextColor, size: 20),
        title: subEntryText(text),
        onTap: onTap,
      );

  static void _showDebuggingCode(BuildContext context, String code) {
    final double debuggingCodeSize = MediaQuery.of(context).size.width;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _dialogBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '调试二维码',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _dialogTitleColor),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: debuggingCodeSize,
                  height: debuggingCodeSize,
                  child: Center(
                    child: QrImageView(
                      data: code,
                      version: QrVersions.auto,
                      size: debuggingCodeSize,
                    ),
                  ),
                ),
                const SizedBox(height: 0),
                entry("复制文本到剪切板", () {
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('已复制')));
                }, Icons.copy),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(85, 0, 0, 0),
              borderRadius: BorderRadius.circular(8),
            ),
            // ignore: prefer_const_constructors
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  color: Colors.white,
                ),
                SizedBox(height: 20),
                Text('上传中...',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showUploadResult(BuildContext context, String tips) =>
      showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            key: const ValueKey('rapid-assistant-upload-result-dialog'),
            backgroundColor: _dialogBackgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "上传结果",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _dialogTitleColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$tips\n\n请将此 ID 提供给开发人员以帮助解决问题',
                    key: const ValueKey('rapid-assistant-upload-result-text'),
                    style:
                        const TextStyle(color: _dialogTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    key: const ValueKey(
                        'rapid-assistant-upload-result-close-action'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          );
        },
      );

  static Future<String> _upload(BuildContext context) async {
    showLoadingDialog(context);
    final resp = await Assistant.uploadLogs();
    // ignore: use_build_context_synchronously
    if (!context.mounted) return "Context is not mounted";
    Navigator.pop(context);
    return resp.success
        ? "成功, 日志 ID: \n${resp.data}"
        : "失败: [${resp.code}] ${resp.message}";
  }

  static void showTerms(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          key: const ValueKey('rapid-assistant-terms-dialog'),
          backgroundColor: _dialogBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "调试政策",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _dialogTitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  _assistantTerms,
                  style: TextStyle(color: _dialogTextColor, fontSize: 12),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('关闭',
                      style: TextStyle(
                          color: _dialogTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          key: const ValueKey('rapid-assistant-dialog'),
          backgroundColor: _dialogBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "诊断工具",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _dialogTitleColor),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    text: '继续使用下列功能即表示同意',
                    style:
                        const TextStyle(color: _dialogTextColor, fontSize: 12),
                    children: [
                      TextSpan(
                        text: '调试政策',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => showTerms(dialogContext),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                entry("上传日志包", () async {
                  final ret = await _upload(context);
                  // ignore: use_build_context_synchronously
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showUploadResult(context, ret);
                }, Icons.cloud_upload_rounded,
                    key: const ValueKey('rapid-assistant-upload-logs-action')),
                const SizedBox(height: 10),
                entry("生成调试码", () {
                  final code = Assistant.createDebuggingCode();
                  Navigator.pop(context);
                  _showDebuggingCode(dialogContext, code);
                }, Icons.qr_code),
                // const SizedBox(height: 10),
                // entry("Instrument Statistics", () {
                //   Navigator.pop(context);
                // }),
              ],
            ),
          ),
        );
      },
    );
  }
}
