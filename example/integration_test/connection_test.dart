import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rapid_kit/rapid_kit.dart';
import 'package:rapid_kit_example/sample/pages/connection.dart';
import 'package:rapid_kit_example/sample/rapid_kit_sample.dart';

import 'support/privacy_consent.dart';

const _inputPath = String.fromEnvironment('RAPID_CONNECTION_CONFIG');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('connection.establish', (tester) async {
    final config = jsonDecode(await File(_inputPath).readAsString())
        as Map<String, dynamic>;
    final evidence = <String, dynamic>{'status': 'failed', 'released': false};
    ConnectionPageState? state;
    try {
      await tester.pumpWidget(const RapidSampleApp());
      await accept_sample_privacy_if_needed(tester);
      final entry = find.byKey(const ValueKey('connection-page-open'));
      await _until(tester, () => entry.evaluate().isNotEmpty,
          const Duration(seconds: 30));
      await tester.tap(entry);
      await tester.pump();
      await _until(
          tester,
          () => find.byType(ConnectionPage).evaluate().isNotEmpty,
          const Duration(seconds: 5));
      state = tester.state<ConnectionPageState>(find.byType(ConnectionPage));
      for (final key in [
        'app_id',
        'package_name',
        'user_account',
        'user_password',
        'device_id'
      ]) {
        final field = find.byKey(ValueKey('connection-$key'));
        await tester.ensureVisible(field);
        await tester.enterText(field, config[key] as String);
      }
      final connect = find.byKey(const ValueKey('connection-connect'));
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await _until(
          tester, () => state!.sdkState != null, const Duration(seconds: 30));
      await _until(tester, () => state!.sdkState == PipeState.established,
          const Duration(seconds: 20));
      expect(state.sdkState, PipeState.established);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('connection-state')))
              .data,
          'established');
      evidence.addAll({
        'sdk_state': 'established',
        'ui_state': 'established',
        'native_commit': RapidKit.commitHash
      });
      final disconnect = find.byKey(const ValueKey('connection-disconnect'));
      await tester.ensureVisible(disconnect);
      await tester.tap(disconnect);
      await _until(tester, () => state!.released, const Duration(seconds: 30));
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('connection-state')))
              .data,
          'disconnected');
      evidence.addAll({'ui_disconnected': true, 'status': 'passed'});
    } finally {
      if (state != null) {
        try {
          await state.disconnect();
        } catch (_) {
          evidence['cleanup_error'] = true;
        }
        evidence['released'] = state.released;
      }
      // This marker contains state only; inputs and authentication responses are never emitted.
      debugPrint('RAPID_CONNECTION_RESULT ${jsonEncode(evidence)}');
    }
  });
}

Future<void> _until(
    WidgetTester tester, bool Function() predicate, Duration bound) async {
  final deadline = DateTime.now().add(bound);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline))
      fail('connection state deadline exceeded');
    await tester.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  await tester.pump();
}
