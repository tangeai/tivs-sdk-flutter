part of '../rapid_kit_sample_pages.dart';

class FirmwarePage extends StatefulWidget {
  final String deviceId;

  const FirmwarePage({super.key, required this.deviceId});

  @override
  State<FirmwarePage> createState() => _FirmarePageState();
}

class _FirmarePageState extends LifecycleAwareState<FirmwarePage> {
  late String _deviceId;
  FirmwareVersion? _firmwareVersion;

  FirmwareStatePolling? _firmwareStatePolling;

  bool _polling = false;
  int? _download_progress;
  Ret? _upgrade_result;
  bool _upgrade_timed_out = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('固件升级', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    final available = _firmwareVersion?.available?.version?.isNotEmpty == true;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (_polling || _upgrade_result != null)
          FirmwareUpgradeStatusCard(
            upgrading: _polling,
            progress: _download_progress,
            result: _upgrade_result,
            timed_out: _upgrade_timed_out,
            on_retry: available && !_polling ? _onPerformUpgrade : null,
            on_refresh: _load,
          ),
        _buildRoundedRectangleWithIconAndText(icon: Icons.numbers, text: "固件ID： ${_firmwareVersion?.current?.id ?? ""}"),
        _buildRoundedRectangleWithIconAndText(icon: Icons.info, text: "版本号： ${_firmwareVersion?.current?.version ?? "Unknown"}"),
        GestureDetector(
          onTap: available && !_polling ? _onPerformUpgrade : null,
          child: _buildRoundedRectangleWithIconAndText(
              icon: Icons.upcoming_sharp,
              text: available ? "有新版本，点击升级！\n新版本 ${_firmwareVersion?.available?.version}：${_firmwareVersion?.available?.description}" : "已是最新版本",
              textColor: const Color.fromRGBO(4, 145, 49, 1)),
        ),
      ],
    );
  }

  void _onPerformUpgrade() async {
    final available = _firmwareVersion?.available?.version?.isNotEmpty == true;
    if (!available || _polling) return;

    setState(() {
      _polling = true;
      _download_progress = null;
      _upgrade_result = null;
      _upgrade_timed_out = false;
    });

    Ret resp;
    try {
      resp = await FirmwareService.performUpgrade(_deviceId, _firmwareVersion?.available?.version ?? "");
    } catch (error) {
      if (!mounted) return;
      _finish_upgrade(Ret.error(-1, '无法发起升级：$error'));
      return;
    }

    if (!mounted) return;
    if (resp.success) {
      _firmwareStatePolling?.stop();
      _firmwareStatePolling = FirmwareStatePolling.create(_deviceId, _firmwareVersion?.available?.version ?? "");
      _firmwareStatePolling?.progress_listener = (progress) {
        if (!mounted || !_polling) return;
        setState(() {
          _download_progress = progress.clamp(0, 100).toInt();
        });
      };
      _firmwareStatePolling?.listener = (ret) {
        if (!mounted) return;
        _finish_upgrade(ret, timed_out: ret.code == FirmwareStatePolling.errorTimeout);
        if (ret.success) _load();
      };
      _firmwareStatePolling?.start();
    } else {
      _finish_upgrade(resp);
    }
  }

  void _finish_upgrade(Ret result, {bool timed_out = false}) {
    setState(() {
      _polling = false;
      _upgrade_result = result;
      _upgrade_timed_out = timed_out;
    });
  }

  Widget _buildRoundedRectangleWithIconAndText(
      {required IconData icon, required String text, Color textColor = SampleThemeConfigure.colorTextPrimary}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: SampleThemeConfigure.colorPrimary),
          const SizedBox(width: 20),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _deviceId = widget.deviceId;
    _load();
  }

  @override
  void dispose() {
    super.dispose();

    _firmwareStatePolling?.stop();
  }

  void _load() async {
    final resp = await FirmwareService.queryCurrentVersion(_deviceId);
    if (!mounted) return;
    if (resp.success) {
      setState(() {
        _firmwareVersion = resp.data;
      });
    } else {
      SnackTips.show(context, "Faild: ${resp.code} ${resp.message}");
    }
  }
}

class FirmwareUpgradeStatusCard extends StatelessWidget {
  final bool upgrading;
  final int? progress;
  final Ret? result;
  final bool timed_out;
  final VoidCallback? on_retry;
  final VoidCallback? on_refresh;

  const FirmwareUpgradeStatusCard({
    super.key,
    required this.upgrading,
    this.progress,
    this.result,
    this.timed_out = false,
    this.on_retry,
    this.on_refresh,
  });

  @override
  Widget build(BuildContext context) {
    final success = result?.success == true;
    final color = upgrading ? Colors.blue.shade700 : success ? Colors.green.shade700 : Colors.red.shade700;
    final title = upgrading ? '固件升级中' : success ? '升级成功' : timed_out ? '等待升级结果超时' : '升级失败';
    final downloading = progress != null && progress! < 100;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(upgrading ? Icons.system_update : success ? Icons.check_circle : Icons.error, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          if (upgrading) ...[
            Text(progress == null ? '等待固件下载进度…' : downloading ? '正在下载固件：$progress%' : '下载完成 100%，等待设备完成升级…'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: downloading ? progress! / 100 : null, color: color),
            const SizedBox(height: 12),
            const Text('请保持设备通电和网络连接，升级结果将在此处显示。'),
          ] else ...[
            Text(success ? '设备固件已升级成功。' : timed_out ? '暂未确认升级结果，设备可能仍在升级。请先查询设备版本，再决定是否重试。' : '本次升级未完成，请查看下方原因并重试。'),
            if (!success && !timed_out)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SelectableText('失败原因：${result?.message ?? "未知错误"}\n错误码：${result?.code ?? "未知"}'),
              ),
            if (!success)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (on_refresh != null) OutlinedButton(onPressed: on_refresh, child: const Text('查询设备版本')),
                    if (on_retry != null) ElevatedButton(onPressed: on_retry, child: const Text('重新升级')),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
