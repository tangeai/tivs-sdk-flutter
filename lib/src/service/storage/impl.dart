import 'struct.dart';
import '../http/http_builder.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class StorageServiceImpl {
  static const String _apiVersionHeader = 'X-Tg-Api-Version';
  static const String _apiVersion = '2.1';

  static Future<Resp<CloudRecordIndexPacket>> listRecords(
      String deviceId, String date) async {
    final resp = await Http.create()
        .path('/v2/cloud/videos/$deviceId/$date')
        .header(_apiVersionHeader, _apiVersion)
        .get();

    if (resp.success) {
      try {
        final packet = CloudRecordIndexPacket.fromJson(resp.data ?? '');
        if (packet.list.isEmpty) {
          return Resp.error(
              cloudRecordIndexErrorNoRecord, 'No record for date');
        }
        return Resp.success(packet);
      } catch (_) {
        return Resp.error(-1, 'Failed to parse response');
      }
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? 'Unknown Error');
    }
  }
}
