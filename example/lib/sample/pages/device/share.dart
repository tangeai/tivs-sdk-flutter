part of '../rapid_kit_sample_pages.dart';

class SharePage extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const SharePage({super.key, required this.deviceId, required this.deviceName});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends LifecycleAwareState<SharePage> {
  late String _deviceId;
  late String _deviceName;

  SharingOverview? _overview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: Text(
        '$_deviceName共享管理',
        style: const TextStyle(fontSize: 16, color: SampleThemeConfigure.colorPrimary),
      ),
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

  Widget _buildRootBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _toShare(),
          const SizedBox(height: 16),
          _overviewBody(),
        ],
      ),
    );
  }

  Expanded _overviewBody() {
    final count = _overview?.list?.length ?? 0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("已共享", textAlign: TextAlign.left),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: count < 1 ? _emptyView() : _overviewList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.crisis_alert_rounded,
          size: 40.0,
          color: SampleThemeConfigure.colorPrimary,
        ),
        SizedBox(height: 12.0),
        Text(
          "还没有分享给任何人噢",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SampleThemeConfigure.colorPrimary,
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }

  ListView _overviewList() {
    return ListView.builder(
      itemCount: _overview?.list?.length ?? 0,
      itemBuilder: (context, index) {
        return _recipientCard(_overview!.list![index]);
      },
    );
  }

  Container _recipientCard(Recipient recipient) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(8.0),
      height: 80.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_circle_sharp,
                size: 40,
                color: SampleThemeConfigure.colorPrimary,
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(recipient.nickName ?? "用户 ${recipient.userId}", style: const TextStyle(fontSize: 14.0)),
                  Text("分享于 ${recipient.shareTime ?? ""}", style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              final resp = await SharingService.removeRecipient(_deviceId, recipient.shareId ?? 0, recipient.shareType ?? 0);
              if (!mounted) return;
              if (resp.success) {
                _loadSharingOverview();
              } else {
                SnackTips.show(context, "Faild: ${resp.message}");
              }
            },
            child: _removeSharing(),
          ),
        ],
      ),
    );
  }

  Container _removeSharing() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 144, 35, 27),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Text(
        "取消共享",
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Column _toShare() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("去共享", textAlign: TextAlign.left),
        const SizedBox(height: 10),
        _createCode(),
        _shareTo(),
      ],
    );
  }

  Widget _createCode() {
    return _shareBaseButton(onTap: () => _onCreateInviteCode(), text: "生成分享码", iconData: Icons.code, iconSize: 24.0);
  }

  Widget _shareTo() {
    return _shareBaseButton(onTap: () => _onShareToAccount(), text: "分享给好友", iconData: Icons.person_add, iconSize: 24.0);
  }

  void _onShareToAccount() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('分享给好友'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '对方的手机号或者邮箱',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 取消按钮关闭对话框
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: const Text('账号不能为空'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  final response = await SharingService.to(_deviceId, account: controller.text);
                  if (!mounted) return;
                  if (!response.success) {
                    SnackTips.show(context, "Error: ${response.message}");
                  } else {
                    SnackTips.show(context, "分享成功");
                    _loadSharingOverview();
                  }
                  Navigator.of(context).pop(); // 异步操作完成后关闭对话框
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void _onCreateInviteCode() async {
    final response = await SharingService.generateInvitation(_deviceId);
    if (!mounted) return;
    if (!response.success) {
      SnackTips.show(context, "Error: ${response.message}");
      return;
    }

    final code = response.data ?? "unknown";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('分享码'),
          content: Text(code),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                SnackTips.show(context, "已拷贝到剪贴板，可以直接粘贴发送给好友了");
                Navigator.of(context).pop();
              },
              child: const Text('拷贝'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _shareBaseButton({
    required VoidCallback onTap,
    required String text,
    required IconData iconData,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        padding: const EdgeInsets.all(16.0),
        height: 60.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  iconData,
                  size: iconSize,
                  color: SampleThemeConfigure.colorPrimary,
                ),
                const SizedBox(width: 12.0),
                Text(
                  text,
                  style: const TextStyle(color: SampleThemeConfigure.colorTextPrimary),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: SampleThemeConfigure.colorTextHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _deviceId = widget.deviceId;
    _deviceName = widget.deviceName;
    _loadSharingOverview();
  }

  void _loadSharingOverview() async {
    final resp = await SharingService.overview(_deviceId);
    if (!mounted) return;
    if (resp.success) {
      setState(() {
        _overview = resp.data;
      });
    } else {
      SnackTips.show(context, "Faild: ${resp.message}");
    }
  }
}
