// ignore_for_file: non_constant_identifier_names
part of 'library.dart';

@visibleForTesting
abstract class RecordListTransport {
  Future<Resp<RecordIndexPacket>> fetch(String date);
  Future<void> close();
}

@visibleForTesting
class RecordListQueryBudget {
  RecordListQueryBudget({this.capacity})
      : assert(capacity == null || capacity > 0);
  final int? capacity;
  final _waiting = <_RecordListAttempt>[];
  int _held = 0;
  Completer<void>? _idle;

  Future<void> get _when_idle => _idle?.future ?? Future.value();

  void _acquire(_RecordListAttempt attempt, VoidCallback start) {
    attempt.start = start;
    _waiting.add(attempt);
    _dispatch();
  }

  void _release(_RecordListAttempt attempt) {
    _waiting.remove(attempt);
    attempt.start = null;
    if (attempt.acquired) {
      attempt.acquired = false;
      _held--;
    }
    _dispatch();
    if (_held == 0 && _waiting.isEmpty) {
      _idle?.complete();
      _idle = null;
    }
  }

  void _dispatch() {
    while ((capacity == null || _held < capacity!) && _waiting.isNotEmpty) {
      final attempt = _waiting.removeAt(0);
      _idle ??= Completer<void>();
      attempt.acquired = true;
      _held++;
      final start = attempt.start;
      attempt.start = null;
      start!();
    }
  }
}

class RecordListQuery {
  RecordListQuery(String deviceId,
      {@Deprecated('The native record query timeout is fixed at 10 seconds.')
      Duration timeout = const Duration(seconds: 10),
      @visibleForTesting RecordListTransport Function()? transportFactory,
      @visibleForTesting RecordListQueryBudget? budget})
      : _budget = budget ?? _default_budget,
        _transportFactory =
            transportFactory ?? (() => _NativeRecordListTransport(deviceId));

  /// Reuses the established pipe. A pending or draining query returns code 3.
  RecordListQuery.shared(Pipe pipe,
      {@Deprecated('The native record query timeout is fixed at 10 seconds.')
      Duration timeout = const Duration(seconds: 10),
      @visibleForTesting RecordListQueryBudget? budget})
      : _budget = budget ?? _default_budget,
        _transportFactory = (() => _SharedRecordListTransport(pipe));

  static final _default_budget = RecordListQueryBudget();
  static Future<void> wait_for_all_cleanup() => _default_budget._when_idle;
  final RecordListQueryBudget _budget;
  final RecordListTransport Function() _transportFactory;
  final _cleanups = <Future<void>>{};
  Object? _cleanup_error;
  _RecordListAttempt? _active;
  bool _disposed = false;

  Future<Resp<RecordIndexPacket>> load(String date) {
    if (_disposed) return Future.value(Resp.error(4, 'Record query disposed'));
    if (_cleanup_error != null) {
      return Future.value(Resp.error(4, 'Record query cleanup failed'));
    }
    if (_active != null)
      return Future.value(Resp.error(3, 'Record list query already pending'));
    final attempt = _RecordListAttempt();
    _active = attempt;
    _budget._acquire(attempt, () => _start(attempt, date));
    return attempt.result.future;
  }

  void _start(_RecordListAttempt attempt, String date) {
    try {
      attempt.transport = _transportFactory();
    } catch (error) {
      _finish(attempt, Resp.error(4, 'Record query creation failed: $error'));
      return;
    }
    Future.sync(() => attempt.transport!.fetch(date)).then(
      (result) => _finish(attempt, result),
      onError: (Object error, StackTrace stack) =>
          _finish(attempt, Resp.error(4, 'Record list query failed: $error')),
    );
  }

  void cancel() {
    final attempt = _active;
    if (attempt != null) {
      _finish(attempt, Resp.error(4, 'Record list query cancelled'));
    }
  }

  Future<Resp<void>> dispose() {
    _disposed = true;
    cancel();
    return wait_for_cleanup();
  }

  /// Waits for scheduled cleanup; use dispose() to also cancel active work.
  Future<Resp<void>> wait_for_cleanup() async {
    await Future.wait(_cleanups.toList());
    return _cleanup_error == null
        ? Resp.success(null)
        : Resp.error(4, 'Record query cleanup failed: $_cleanup_error');
  }

  void _finish(_RecordListAttempt attempt, Resp<RecordIndexPacket> response) {
    if (!identical(_active, attempt)) return;
    _active = null;
    final transport = attempt.transport;
    if (transport == null) {
      _budget._release(attempt);
    } else {
      late final Future<void> cleanup;
      cleanup = Future.sync(transport.close).then<void>(
        (_) => _budget._release(attempt),
        onError: (Object error, StackTrace stack) {
          _cleanup_error = error;
          final active = _active;
          if (active != null) {
            _finish(active, Resp.error(4, 'Record query cleanup failed'));
          }
        },
      ).whenComplete(() => _cleanups.remove(cleanup));
      _cleanups.add(cleanup);
    }
    attempt.result.complete(response);
  }
}

class _RecordListAttempt {
  RecordListTransport? transport;
  VoidCallback? start;
  bool acquired = false;
  final result = Completer<Resp<RecordIndexPacket>>();
}

class _NativeRecordListTransport extends _SharedRecordListTransport {
  _NativeRecordListTransport(String deviceId)
      : super(Pipe.create(deviceId), ownsPipe: true);
}

class _SharedRecordListTransport implements RecordListTransport {
  _SharedRecordListTransport(this._pipe, {this.ownsPipe = false});

  final Pipe _pipe;
  final bool ownsPipe;
  final _response = Completer<Resp<RecordIndexPacket>>();
  RapidNativeInstructStandard? _instruct;
  bool _closed = false;

  @override
  Future<Resp<RecordIndexPacket>> fetch(String date) {
    if (!_pipe.isEstablished) {
      return Future.value(Resp.error(1, 'Record query connection unavailable'));
    }
    final params = InstructStandard.buildListRecordIndexParams(date);
    final instruct = RapidNativeInstructStandard(_pipe._nativePipe)..create();
    _instruct = instruct;
    Logging.i('RecordListQuery',
        '[query.shared] date=$date pipe=${_pipe._instanceId}');
    instruct.request('list_record_index', params.json(), (String response) {
      if (_closed || _response.isCompleted) return;
      try {
        final value = json.decode(response) as Map<String, dynamic>;
        final code = value['code'] as int? ?? -1;
        final data =
            value['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        _response.complete(InstructStandard._recordListResponse(code == 0
            ? Resp.success(data)
            : Resp.error(
                code,
                code == 4
                    ? 'Reconnect the pipe before retrying the record list query'
                    : 'Record list query failed (code=$code)',
                data)));
      } catch (error) {
        _response
            .complete(Resp.error(4, 'Invalid record list response: $error'));
      }
    });
    return _response.future;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_response.isCompleted) {
      _response.complete(Resp.error(4, 'Record query closed'));
    }
    _instruct?.destroy();
    _instruct = null;
    if (ownsPipe) _pipe.destroy();
  }
}
