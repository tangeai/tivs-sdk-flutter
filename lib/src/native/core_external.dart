part of 'library.dart';

typedef RapidExternalDataListener = void Function(
    int type, int data1, int data2, Uint8List? buffer);

ReceivePort createRapidExternalDataPort(RapidExternalDataListener listener) {
  final receivePort = ReceivePort();
  receivePort.listen((dynamic message) {
    if (message is! List<dynamic> || message.length != 4) return;
    final type = message[0] as int? ?? 0;
    final data1 = message[1] as int? ?? 0;
    final data2 = message[2] as int? ?? 0;
    final buffer = message[3] as Uint8List?;
    listener(type, data1, data2, buffer);
  });
  return receivePort;
}
