part of '../library.dart';

class Assistant {
  static const _dialogBackgroundColor = Color(0xFFFFF8E8);
  static const _dialogTitleColor = Color(0xFF8E7AB5);
  static const _dialogTextColor = Color(0xFF666666);

  Assistant._();
  static Future<String> _uploadInternal() => compute(_upload, null);
  static String _upload(dynamic _) => RapidNativeLogging().upload();

  static String createDebuggingCode() => RapidNativeDebuggingCode.create();

  static bool applyDebuggingCode(String code) => RapidNativeDebuggingCode.apply(code);

  static void showEntry(BuildContext context) => _AssistantDialog.show(context);

  static Future<Resp<String>> uploadLogs() async {
    final result = await _uploadInternal();
    return result.isNotEmpty ? Resp.success(result.replaceFirst("/app-log/", "").replaceFirst(".zip", "")) : Resp.error(-1, "Failed to upload logs");
  }
}
