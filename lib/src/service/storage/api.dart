import 'impl.dart';
export 'struct.dart';

class StorageService {
  static const int errorNoRecord = cloudRecordIndexErrorNoRecord;

  static Future<Resp<CloudRecordIndexPacket>> listRecords(
          String deviceId, String date) async =>
      StorageServiceImpl.listRecords(deviceId, date);
}
