import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './rapid_kit_sample.dart';
import 'dart:io' show Platform;
import 'pages/launch/privacy_gate.dart';

void launchSample() {
  _configureSystemUIOverlay();
  runApp(const RapidSampleApp());
}

class RapidSampleApp extends StatelessWidget {
  const RapidSampleApp({
    super.key,
    this.initialDebuggingCode,
    this.initialTargetDeviceId,
  });

  final String? initialDebuggingCode;
  final String? initialTargetDeviceId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TG Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          scaffoldBackgroundColor: SampleThemeConfigure.colorBackground),
      home: PrivacyGate(
        background: const LoginPage(privacy_preview: true),
        builder: (context) => SplashPage(
          initialDebuggingCode: initialDebuggingCode,
          initialTargetDeviceId: initialTargetDeviceId,
        ),
      ),
      navigatorObservers: [routeObserver],
      builder: (context, child) {
        return child!;
      },
    );
  }
}

void _configureSystemUIOverlay() {
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
}
