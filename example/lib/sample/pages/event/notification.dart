part of '../rapid_kit_sample_pages.dart';

class NotificationPage extends StatefulWidget {
  final String deviceId;

  const NotificationPage({super.key, required this.deviceId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends LifecycleAwareState<NotificationPage> {
  RemotePushConfigure? _remotePushConfigure;
  LocalPushConfigure? _localPushConfigure;
  late String _deviceId;
  final _intervalSeconds = [60, 180, 300, 600, 1800];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('报警推送设置',
          style: TextStyle(color: SampleThemeConfigure.colorPrimary, fontSize: 16)),
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
    final switchOn = _remotePushConfigure?.enable ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _notificationSwitch(),
        const SizedBox(height: 16),
        _notificationInterval(),
        const SizedBox(height: 32),
        if (switchOn)
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text("推送事件类型",
                style: TextStyle(fontSize: 18.0, color: SampleThemeConfigure.colorPrimary)),
          ),
        if (switchOn) _pushCategories(),
      ],
    );
  }

  Expanded _pushCategories() {
    return Expanded(
      child: ListView.builder(
        itemCount: _remotePushConfigure?.switcher?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          return SwitchListTile(
            title: Text(
              _remotePushConfigure?.switcher?[index].categoryName ?? '',
              style: _primaryTextStyle(),
            ),
            value: _remotePushConfigure?.switcher?[index].enable ?? false,
            activeTrackColor: SampleThemeConfigure.colorPrimary,
            onChanged: (bool newValue) async {
              _remotePushConfigure?.switcher?[index].enable = newValue;
              _localPushConfigure = LocalPushConfigure.fromRemote(_remotePushConfigure!);
              _updateNotificationSettings();
            },
          );
        },
      ),
    );
  }

  SwitchListTile _notificationSwitch() {
    return SwitchListTile(
      title: Text(
        '报警消息推送',
        style: _primaryTextStyle(),
      ),
      subtitle: Text('检测到事件时，推送消息给手机', style: _secondaryTextStyle()),
      value: _remotePushConfigure?.enable ?? false,
      activeTrackColor: SampleThemeConfigure.colorPrimary,
      onChanged: (bool newValue) async {
        if (newValue && _localPushConfigure != null) {
          // 开启全局开关时，必须设置至少一个分类的推送开关！
          if (_localPushConfigure!.tagWhichNeedToPush?.isEmpty ?? true) {
            _localPushConfigure!.tagWhichNeedToPush = ["body"];
          }
        }
        _localPushConfigure?.enable = newValue;
        _updateNotificationSettings();
      },
    );
  }

  Widget _notificationInterval() {
    final interval = _remotePushConfigure?.interval ?? 0;
    return ListTile(
      title: Text(
        '报警时间间隔',
        style: _primaryTextStyle(),
      ),
      subtitle: Text('报警较多可拉大间隔减少干扰', style: _secondaryTextStyle()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (interval == 0 ? "未设置" : "${interval ~/ 60}分钟"),
            style: _secondaryTextStyle(),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios, size: 16, color: SampleThemeConfigure.colorTextHint),
        ],
      ),
      onTap: () => _onPickInterval(),
    );
  }

  void _onPickInterval() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0), // 整体边界间距
          child: Wrap(
            children: _intervalSeconds.map((int interval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  title: Text("${interval ~/ 60}分钟"),
                  onTap: () async {
                    _localPushConfigure?.interval = interval;
                    _updateNotificationSettings();
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

  TextStyle _secondaryTextStyle() =>
      const TextStyle(fontSize: 14.0, color: Color.fromRGBO(125, 123, 123, 1));

  TextStyle _primaryTextStyle() => const TextStyle(
      fontSize: 16.0, color: SampleThemeConfigure.colorTextPrimary, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _deviceId = widget.deviceId;
    _loadNotificationSettings();
  }

  void _updateNotificationSettings() async {
    if (_localPushConfigure == null) return;
    final resp = await EventService.updateNotificationSettings(_deviceId, _localPushConfigure!);
    if (!mounted) return;
    if (!resp.success) {
      SnackTips.show(context, "Faild: ${resp.message}");
    }

    _loadNotificationSettings();
  }

  void _loadNotificationSettings() async {
    final resp = await EventService.currentNotificationSettings(_deviceId);
    if (!mounted) return;
    if (resp.success) {
      _localPushConfigure = LocalPushConfigure.fromRemote(resp.data!);
      setState(() {
        _remotePushConfigure = resp.data;
      });
    } else {
      SnackTips.show(context, "Faild: ${resp.message}");
    }
  }
}
