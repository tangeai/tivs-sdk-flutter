import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rapid_kit/rapid_kit.dart';

/// A manually usable connection-only example; no media player is created.
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => ConnectionPageState();
}

class ConnectionPageState extends State<ConnectionPage> {
  final _fields = <String, TextEditingController>{
    'app_id': TextEditingController(text: '2818153'),
    'package_name':
        TextEditingController(text: 'com.tange.ai.iot.client.sample'),
    'user_account': TextEditingController(),
    'user_password': TextEditingController(),
    'device_id': TextEditingController(),
  };
  Pipe? _pipe;
  VoidCallback? _cancelListener;
  bool _busy = false;
  bool _disposed = false;
  Future<void>? _releaseFuture;
  String _status = 'disconnected';

  PipeState? get sdkState => _pipe?.currentState();
  bool get released => _pipe == null && !_busy;

  Future<void> _connect() async {
    if (_busy ||
        _pipe != null ||
        _fields.values.any((field) => field.text.trim().isEmpty)) return;
    final input = _fields.map((key, field) => MapEntry(key, field.text));
    setState(() {
      _busy = true;
      _status = 'initializing';
    });
    try {
      final initialized = await RapidKit.initialize(Configurations(
        id: input['app_id']!,
        package: input['package_name']!,
        debugging: false,
        httpLogging: false,
      )).timeout(const Duration(seconds: 20));
      if (_disposed) return;
      if (!initialized) throw StateError('initialize failed');
      final login = await AccountService.login(
        input['user_account']!,
        input['user_password']!,
      ).timeout(const Duration(seconds: 20));
      if (_disposed) return;
      if (!login.success || login.data?.accessToken == null)
        throw StateError('login failed');
      final auth = await Authenticate.configure(login.data!.accessToken!)
          .timeout(const Duration(seconds: 20));
      if (_disposed) return;
      if (!auth.success) throw StateError('authentication failed');
      final pipe = Pipe.create(input['device_id']!);
      _pipe = pipe;
      _cancelListener = pipe.listen((state) {
        if (mounted) setState(() => _status = state.name);
      });
      pipe.establish();
      if (mounted) setState(() => _status = pipe.currentState().name);
    } catch (_) {
      if (!_disposed && mounted) setState(() => _status = 'failed');
    } finally {
      if (!_disposed && mounted) setState(() => _busy = false);
    }
  }

  Future<void> disconnect() async {
    final active = _releaseFuture;
    if (active != null) return active;
    final operation = _disconnect();
    _releaseFuture = operation;
    try {
      await operation;
    } finally {
      _releaseFuture = null;
    }
  }

  Future<void> _disconnect() async {
    final pipe = _pipe;
    if (pipe == null) return;
    if (!_disposed && mounted)
      setState(() {
        _busy = true;
        _status = 'disconnecting';
      });
    pipe.abolish();
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (pipe.currentState() == PipeState.established ||
        pipe.currentState() == PipeState.attempting) {
      if (DateTime.now().isAfter(deadline)) {
        if (!_disposed && mounted)
          setState(() {
            _busy = false;
            _status = 'cleanup failed';
          });
        throw TimeoutException('SDK disconnect timed out');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _cancelListener?.call();
    _cancelListener = null;
    pipe.destroy();
    _pipe = null;
    if (!_disposed && mounted)
      setState(() {
        _busy = false;
        _status = 'disconnected';
      });
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelListener?.call();
    unawaited(disconnect());
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pipe == null && !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Connection check')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final entry in _fields.entries)
              TextField(
                key: ValueKey('connection-${entry.key}'),
                controller: entry.value,
                enabled: !_busy && _pipe == null,
                obscureText: entry.key == 'user_password',
                decoration:
                    InputDecoration(labelText: entry.key.replaceAll('_', ' ')),
              ),
            const SizedBox(height: 16),
            Text(_status, key: const ValueKey('connection-state')),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('connection-connect'),
              onPressed: _busy || _pipe != null ? null : _connect,
              child: const Text('Connect'),
            ),
            ElevatedButton(
              key: const ValueKey('connection-disconnect'),
              onPressed: _busy || _pipe == null ? null : disconnect,
              child: const Text('Disconnect'),
            ),
          ]),
        ),
      ),
    );
  }
}
