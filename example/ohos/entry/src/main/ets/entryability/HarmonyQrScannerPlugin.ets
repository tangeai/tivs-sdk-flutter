import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  MethodCall,
  MethodChannel,
} from '@ohos/flutter_ohos';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import UIAbility from '@ohos.app.ability.UIAbility';

const TAG = 'HarmonyQrScannerPlugin';
const METHOD_CHANNEL_NAME =
  'com.tange.ai/rapid_kit_example/method.channel/harmony_qr_scanner';
const USER_CANCELED_ERROR = 1000500002;

export default class HarmonyQrScannerPlugin implements FlutterPlugin, AbilityAware {
  private methodChannel?: MethodChannel;
  private ability?: UIAbility;
  private scanning: boolean = false;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      METHOD_CHANNEL_NAME,
    );
    const that = this;
    this.methodChannel.setMethodCallHandler({
      onMethodCall(call: MethodCall, result: MethodResult): void {
        if (call.method === 'scanQrCode') {
          that.scanQrCode(result);
          return;
        }
        result.notImplemented();
      },
    });
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = undefined;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(): void {
    this.ability = undefined;
  }

  getUniqueClassName(): string {
    return TAG;
  }

  private scanQrCode(result: MethodResult): void {
    if (this.scanning) {
      result.error('scan_in_progress', 'A QR code scan is already in progress.', null);
      return;
    }
    if (this.ability === undefined) {
      result.error('scanner_unavailable', 'The current ability is unavailable.', null);
      return;
    }

    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: true,
    };
    this.scanning = true;
    try {
      scanBarcode.startScanForResult(this.ability.context, options)
        .then((scanResult: scanBarcode.ScanResult) => {
          this.scanning = false;
          result.success(scanResult.originalValue);
        })
        .catch((error: BusinessError) => {
          this.scanning = false;
          if (error.code === USER_CANCELED_ERROR) {
            result.success(null);
            return;
          }
          result.error('scan_failed', error.message, error.code);
        });
    } catch (error) {
      this.scanning = false;
      const message = error instanceof Error ? error.message : String(error);
      result.error('scan_failed', message, null);
    }
  }
}
