// ignore_for_file: non_constant_identifier_names
part of 'library.dart';

void _destroy_record_query_pipe(List<Object> message) {
  final pipe = Pointer<Void>.fromAddress(message[0] as int);
  if (coreApiPipeBinding.RAPID_Core_PipeProxy_DestroyRecordQuery(pipe) != 1) {
    throw StateError('Native query cleanup rejected a shared Pipe');
  }
  Isolate.exit(message[1] as SendPort, true);
}

Future<void> _release_record_query_pipe(
    int address, void Function() transfer) async {
  final events = ReceivePort();
  try {
    final worker = await Isolate.spawn(
      _destroy_record_query_pipe,
      <Object>[address, events.sendPort],
      paused: true,
      onError: events.sendPort,
      onExit: events.sendPort,
      debugName: 'rapid-record-query-cleanup',
    );
    transfer();
    worker.resume(worker.pauseCapability!);
    final result = await events.first;
    if (result != true) {
      throw StateError('Record query cleanup worker did not complete: $result');
    }
  } finally {
    events.close();
  }
}
