part of '../rapid_kit_sample_pages.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends LifecycleAwareState<AccountPage> {
  UserInfo? _userInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('rapid-account-page-root'),
      appBar: AppBar(
        title: const Text('账户与设置',
            style: TextStyle(
                color: SampleThemeConfigure.colorPrimary, fontSize: 16)),
        backgroundColor: SampleThemeConfigure.colorBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: SampleThemeConfigure.colorPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: _buildPageBody(),
    );
  }

  TextStyle _secondaryTextStyle() =>
      const TextStyle(fontSize: 14.0, color: Color.fromRGBO(125, 123, 123, 1));

  Widget buildSettingItem(
    String title,
    VoidCallback onTap, {
    Key? key,
    Color textColor = SampleThemeConfigure.colorTextSub,
  }) {
    return ListTile(
      key: key,
      title: Text(
        title,
        style: TextStyle(fontSize: 14.0, color: textColor),
      ),
      trailing: SizedBox(
        width: 40.0,
        child: Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.arrow_forward_ios,
              size: 14, color: SampleThemeConfigure.colorTextHint),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildPageBody() {
    String nickName = "昵称未设置";
    if (_userInfo?.nickName?.isNotEmpty == true) {
      nickName = _userInfo!.nickName!;
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildNickName(nickName),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: _buildSettings(),
          ),
        ),
      ],
    );
  }

  Column _buildSettings() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        buildSettingItem("修改密码", _onChangePassword),
        buildSettingItem(
          "退出登录",
          _onLogout,
          key: const ValueKey('rapid-account-logout-action'),
        ),
        buildSettingItem("删除账号", _confirmDelete,
            textColor: const Color.fromRGBO(192, 51, 8, 1)),
      ],
    );
  }

  Row _buildNickName(String nickName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_circle,
          color: SampleThemeConfigure.colorPrimary,
          size: 60.0,
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickName,
                style: const TextStyle(
                  fontSize: 18.0,
                ),
              ),
              Text(
                _userInfo?.account ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              foregroundColor: SampleThemeConfigure.colorForeground),
          onPressed: () {
            showEditDialog(context);
          },
          child: const Text('修改昵称'),
        ),
      ],
    );
  }

  void _onLogout() {
    context.showSnackDialog(
      title: "退出登录",
      content: "确定要退出登录吗？",
      onConfirm: () {
        _confirmLogout();
      },
      onCancel: () {},
    );
  }

  void _confirmLogout() async {
    PushNotificationCoordinator.instance.handleAuthenticationInvalidated();
    await SharedPreferencesUtil.instance
        .setString(SampleConstants.storageKeyLoginToken, "");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );

    PersistentChannel.disconnect();
  }

  void _confirmDelete() {
    context.showSnackDialog(
        title: "注销账号",
        content:
            "确定要注销吗？\n\n注销账号后，您在本应用的所有数据将被永久删除！包括但不限于你的个人信息与账户设置、购买与支付记录等。\n\n若确认要注销，请首先确认该账号没有与任何设备绑定，如有请删除后再尝试注销。",
        onConfirm: () async {
          _onDeleteAccount();
        },
        onCancel: () {});
  }

  void _onDeleteAccount() async {
    final resp = await AccountService.delete();
    if (!resp.success) {
      SnackTips.show(context, '注销失败： [${resp.code}] ${resp.message}');
      return;
    }

    PushNotificationCoordinator.instance.handleAuthenticationInvalidated();
    await SharedPreferencesUtil.instance
        .setString(SampleConstants.storageKeyLoginAccount, "");
    await SharedPreferencesUtil.instance
        .setString(SampleConstants.storageKeyLoginToken, "");

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _onChangePassword() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('修改密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '旧密码'),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '新密码'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPassword = oldPasswordController.text;
                final newPassword = newPasswordController.text;

                if (oldPassword.isEmpty || newPassword.isEmpty) {
                  SnackTips.show(context, '你需要输入旧密码和新密码');
                  Navigator.of(context).pop();
                  return;
                }

                final ret = await AccountService.changePassword(
                    oldPassword, newPassword);

                if (!mounted) {
                  return;
                }

                if (ret.success) {
                  SnackTips.show(context, '修改成功');
                } else {
                  SnackTips.show(context, '修改失败 [${ret.code}] ${ret.message}');
                }

                Navigator.of(context).pop();
              },
              child: const Text('提交'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final detailResp = await AccountService.detail();
    setState(() {
      _userInfo = detailResp.data;
    });
  }

  void showEditDialog(BuildContext context) {
    TextEditingController textEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置昵称'),
          content: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(hintText: "输入新昵称"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("提交"),
              onPressed: () async {
                String newNickname = textEditingController.text;

                final ret = await AccountService.changeNickname(newNickname);

                if (!mounted) {
                  return;
                }

                if (ret.success) {
                  _loadData();
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
