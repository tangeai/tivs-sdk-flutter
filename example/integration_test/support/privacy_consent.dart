// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> accept_sample_privacy_if_needed(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  final gate = find.byKey(const ValueKey('rapid-privacy-gate'));
  final accept = find.byKey(const ValueKey('rapid-privacy-accept'));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (gate.evaluate().isEmpty) return;
    final button = tester.widget<ElevatedButton>(accept);
    if (button.onPressed == null) continue;
    await tester.tap(accept);
    await tester.pump();
    return;
  }
  throw StateError('Privacy consent did not become available');
}
