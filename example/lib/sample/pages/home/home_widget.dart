part of '../rapid_kit_sample_pages.dart';

Widget homeTitle(BuildContext context) {
  return SizedBox(
    height: 60.0,
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconButtons(context),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: const ValueKey('connection-page-open'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionPage())),
              child: const Text('Connection check'),
            ),
            _assistant(context),
          ],
        ),
      ],
    ),
  );
}

OutlinedButton _assistant(BuildContext context) {
  return OutlinedButton(
    key: const ValueKey('rapid-home-assistant-action'),
    style: OutlinedButton.styleFrom(
      foregroundColor: SampleThemeConfigure.colorPrimary,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minimumSize: const Size(50, 32),
      side:
          const BorderSide(color: SampleThemeConfigure.colorPrimary, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: () => Assistant.showEntry(context),
    child: const Text("诊断工具",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center),
  );
}

void _showPopupMenu(BuildContext context) {
  showMenu<String>(
    context: context,
    color: Colors.white,
    position: const RelativeRect.fromLTRB(100, 80, 16, 0),
    items: [
      _popupMenuAddDevice(),
      if (!Platform.isWindows) _popupMenuLanPreview(),
      _popupMenuGridLive(),
      _popupMenuRecognizeShareCode(),
    ],
    elevation: 100.0,
  ).then((value) {
    if (value != null) {
      _handleMenuSelection(context, value);
    }
  });
}

PopupMenuItem<String> _popupMenuGridLive() {
  return PopupMenuItem<String>(
    value: 'grid_live',
    child: Row(
      children: [
        Icon(
          Icons.grid_view_rounded,
          color: SampleThemeConfigure.colorTextPrimary,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          '宫格预览',
          style: TextStyle(color: SampleThemeConfigure.colorTextPrimary),
        ),
      ],
    ),
  );
}

PopupMenuItem<String> _popupMenuRecognizeShareCode() {
  return PopupMenuItem<String>(
    value: 'accept_share',
    child: Row(
      children: [
        Icon(
          Icons.share,
          color: SampleThemeConfigure.colorTextPrimary,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          '识别分享码',
          style: TextStyle(color: SampleThemeConfigure.colorTextPrimary),
        ),
      ],
    ),
  );
}

PopupMenuItem<String> _popupMenuLanPreview() {
  return PopupMenuItem<String>(
    value: 'lan_preview',
    child: Row(
      children: [
        Icon(
          Icons.preview,
          color: SampleThemeConfigure.colorTextPrimary,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          '局域网预览',
          style: TextStyle(color: SampleThemeConfigure.colorTextPrimary),
        ),
      ],
    ),
  );
}

PopupMenuItem<String> _popupMenuAddDevice() {
  return PopupMenuItem<String>(
    value: 'add',
    child: Row(
      children: [
        Icon(
          Icons.add,
          color: SampleThemeConfigure.colorTextPrimary,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          '添加新设备',
          style: TextStyle(color: SampleThemeConfigure.colorTextPrimary),
        ),
      ],
    ),
  );
}

void _handleMenuSelection(BuildContext context, String value) {
  switch (value) {
    case 'add':
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const BindingPage()));
      break;
    case 'lan_preview':
      _onLanPreviewTap(context);
      break;
    case 'grid_live':
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const GridLivePage()));
      break;
    case 'accept_share':
      _onAcceptShare(context);
      break;
  }
}

void _onLanPreviewTap(BuildContext context) async {
  bool locationPermissionGranted =
      await RuntimePermissions.accessGranted(PermissionType.location);
  if (!context.mounted) return;
  if (!locationPermissionGranted) {
    SnackTips.show(context, "请授予定位权限后，再次点击");
    await RuntimePermissions.requestAccess(PermissionType.location);
  }
  if (!context.mounted) return;
  Navigator.push(context,
      MaterialPageRoute(builder: (context) => const LanPreviewGuidePage()));
}

void _onAcceptShare(BuildContext context) async {
  ClipboardData? clipboardData = await Clipboard.getData('text/plain');
  if (!context.mounted) return;
  final clipboardText = clipboardData?.text ?? '';
  if (clipboardText.isEmpty) {
    SnackTips.show(context, '剪切板为空');
    return;
  }

  final response = await SharingService.peekInvitation(clipboardText);
  if (response.success) {
    String tips = "收到来自";
    if (response.data?.ownerNickName?.isEmpty ?? true) {
      tips += "用户 ${response.data?.ownerUserId} ";
    } else {
      tips += "用户 ${response.data?.ownerNickName} ";
    }
    if (response.data?.deviceName?.first.isEmpty ?? true) {
      tips += "共享的设备，是否接受？";
    } else {
      tips += "共享的设备\"${response.data?.deviceName?.first ?? ""}\"，是否接受？";
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设备共享'),
          content: Text(tips),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 取消按钮关闭对话框
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final resp =
                    await SharingService.acceptInvitation(clipboardText);
                if (!context.mounted) return;
                if (resp.success) {
                  SnackTips.show(context, "接收成功，下拉刷新可见");
                } else {
                  SnackTips.show(
                      context, "Error: [${resp.code}] ${resp.message}");
                }
                Navigator.of(context).pop(); // 确定按钮关闭对话框
              },
              child: const Text('开心收下'),
            ),
          ],
        );
      },
    );
  } else {
    if (!context.mounted) return;
    SnackTips.show(context, "Error: [${response.code}] ${response.message}");
  }
}

Widget _buildIconButtons(BuildContext context) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      IconButton(
        key: const ValueKey('rapid-home-account-action'),
        tooltip: '账户与设置',
        icon: const Icon(Icons.account_circle_rounded,
            size: 36, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AccountPage()));
        },
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_rounded,
            size: 36, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          _showPopupMenu(context);
        },
      ),
    ],
  );
}
