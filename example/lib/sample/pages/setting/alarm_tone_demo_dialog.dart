import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapid_kit/rapid_kit.dart' show Ret, RingtonePacket;

class AlarmToneDemoDialog extends StatefulWidget {
  final Future<Ret> Function(RingtonePacket packet) onUpload;

  const AlarmToneDemoDialog({super.key, required this.onUpload});

  @override
  State<AlarmToneDemoDialog> createState() => _AlarmToneDemoDialogState();
}

class _AlarmToneDemoDialogState extends State<AlarmToneDemoDialog> {
  static const _assetPath = 'assets/audio/alarm_tone_demo.wav';
  static const _fileContentType = 0;
  static const _wavFormat = 0;
  static const _pcmCodec = 52;

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  bool _uploading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  String? _validateId(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '请输入音频 ID';
    final id = int.tryParse(value);
    // 与 Android 的 Int 输入保持一致；具体有效 ID 由设备固件约定。
    if (!RegExp(r'^[+-]?[0-9]+$').hasMatch(value) ||
        id == null ||
        id < -2147483648 ||
        id > 2147483647) {
      return '音频 ID 必须是有效的 32 位整数';
    }
    return null;
  }

  Future<void> _upload() async {
    if (_uploading || !_formKey.currentState!.validate()) return;
    final id = int.parse(_idController.text.trim());
    FocusScope.of(context).unfocus();
    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final data = await rootBundle.load(_assetPath);
      if (!mounted) return;
      // SDK 接收 Base64；保留完整 WAV 文件头和音频数据。
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final packet = RingtonePacket(
        id,
        _fileContentType,
        _wavFormat,
        _pcmCodec,
        base64Encode(bytes),
      );
      final result = await widget.onUpload(packet);
      if (!mounted) return;
      setState(() {
        if (result.success) {
          _successMessage = '音频 ID：$id\n文件大小：${bytes.length} 字节\n'
              'WAV / PCM，8000 Hz，16 bit，单声道\n\n'
              '可点击“警戒语音-立即播放”验证设备播报。';
        } else {
          _error = '上传失败（错误码：${result.code ?? -1}）：'
              '${result.message ?? "设备未返回错误详情"}';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '上传失败：$error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_uploading,
      child: AlertDialog(
        title: Text(_successMessage == null ? '上传内置 WAV' : '上传成功'),
        content: SingleChildScrollView(
          child: _successMessage != null
              ? Text(_successMessage!)
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '示例音频已随 App 打包，无需选择文件。\n'
                        '1 秒提示音：WAV / PCM，8000 Hz，16 bit，单声道。\n\n'
                        '请先通过“查询音频规格与当前铃声”确认设备支持，再填写音频 ID。',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _idController,
                        enabled: !_uploading,
                        keyboardType:
                            const TextInputType.numberWithOptions(signed: true),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: '音频 ID',
                          hintText: '例如 1，以设备约定为准',
                        ),
                        validator: _validateId,
                        onFieldSubmitted: (_) => _upload(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                      if (_uploading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('正在上传示例音频…'),
                      ],
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: _uploading ? null : () => Navigator.of(context).pop(),
            child: Text(_successMessage == null ? '取消' : '关闭'),
          ),
          if (_successMessage == null)
            TextButton(
              onPressed: _uploading ? null : _upload,
              child: const Text('上传示例音频'),
            ),
        ],
      ),
    );
  }
}
