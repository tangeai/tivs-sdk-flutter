part of 'rapid_kit_sample_widget.dart';

class DumpUploadFeedback {
  DumpUploadFeedback._();

  static Future<Resp<String>> uploadLogs(BuildContext context) async {
    final resp = await Assistant.uploadLogs();
    if (!context.mounted) {
      return resp;
    }

    await showResult(context, resp);
    return resp;
  }

  static Future<void> showResult(BuildContext context, Resp<String> resp) {
    final success = resp.success;
    final logId = resp.data ?? '';
    final title = success ? '上传完成' : '上传失败';
    final message = success ? '日志 ID\n$logId\n\n可使用该 ID 拉取日志，或直接提供给工程师排查。' : '日志上传失败。\n[${resp.code}] ${resp.message ?? 'Unknown error'}';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const ValueKey('rapid-dump-result-dialog'),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              color: success ? SampleThemeConfigure.colorTextPrimary : const Color(0xFFE5484D),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: SampleThemeConfigure.colorTextPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            if (success)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: logId));
                  if (!dialogContext.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('日志 ID 已复制')),
                  );
                },
                child: const Text('复制 ID'),
              ),
            FilledButton(
              key: const ValueKey('rapid-dump-result-close-action'),
              style: FilledButton.styleFrom(
                backgroundColor: SampleThemeConfigure.colorPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}
