// ignore_for_file: deprecated_member_use
part of '../rapid_kit_sample_pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.initialDebuggingCode,
    this.initialTargetDeviceId,
  });

  final String? initialDebuggingCode;
  final String? initialTargetDeviceId;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends LifecycleAwareState<SplashPage> {
  var _attemptedCount = 0;
  var _terminated = false;

  @override
  void initState() {
    super.initState();

    _initializeRapidKit();
  }

  void _loadLocalAccessToken() async {
    String? accessToken = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyLoginToken);
    if (!mounted) return;

    if (accessToken == null || accessToken.isEmpty) {
      CenterLoading.hide(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPage(
                  initialDebuggingCode: widget.initialDebuggingCode,
                  initialTargetDeviceId: widget.initialTargetDeviceId)));
      return;
    }

    final resp = await Authenticate.configure(accessToken);
    if (!mounted) return;

    CenterLoading.hide(context);

    if (!resp.success) {
      PushNotificationCoordinator.instance.handleAuthenticationInvalidated();
      await SharedPreferencesUtil.instance
          .remove(SampleConstants.storageKeyLoginToken);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPage(
                  initialDebuggingCode: widget.initialDebuggingCode,
                  initialTargetDeviceId: widget.initialTargetDeviceId)));
      return;
    }

    PushNotificationCoordinator.instance.handleAuthenticationSucceeded();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomePage(initialTargetDeviceId: widget.initialTargetDeviceId)));
  }

  // keep trying to initialize RapidKit until it's successful
  // if failed, delay for few seconds and try again
  _initializeRapidKit() async {
    while (true) {
      if (_terminated || !mounted) break;
      final success = await RapidInitialize.init();
      if (success || _terminated) break;
      setState(() => _attemptedCount++);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (_terminated || !mounted) return;
    await PushNotificationCoordinator.instance.initialize();
    _loadLocalAccessToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('rapid-splash-page-root'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitPulse(
              color: SampleThemeConfigure.colorPrimary,
              size: 60,
            ),
            SizedBox(height: 30.0),
            Text(
              _attemptedCount > 0 ? '初始化中，已经尝试$_attemptedCount次\n可能无法连接网络' : '',
              style: TextStyle(
                color: SampleThemeConfigure.colorPrimary,
                fontSize: 14.0,
              ),
            ),
            if (_attemptedCount >= 3) SizedBox(height: 50.0),
            if (_attemptedCount >= 3) _buildLanButton(),
          ],
        ),
      ),
    );
  }

  void _onLanPreviewTap(BuildContext context) async {
    bool locationPermissionGranted =
        await RuntimePermissions.accessGranted(PermissionType.location);
    if (!context.mounted) return;
    if (!locationPermissionGranted) {
      SnackTips.show(context, "授予定位权限后，再次点击");
      await RuntimePermissions.requestAccess(PermissionType.location);
      return;
    }
    if (!context.mounted) return;
    _terminated = true;
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const LanPreviewGuidePage()));
  }

  Widget _buildLanButton() {
    return ElevatedButton(
      onPressed: () => _onLanPreviewTap(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: SampleThemeConfigure.colorPrimary,
        foregroundColor: SampleThemeConfigure.colorForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: const Text('或者，使用局域网预览'),
    );
  }
}
