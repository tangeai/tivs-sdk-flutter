import { AbilityAware, AbilityPluginBinding, FlutterPlugin, Log, MethodCall, MethodChannel, } from '@ohos/flutter_ohos';
import dataPreferences from '@ohos.data.preferences';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "PreferencesPlugin"
const METHOD_CHANNEL_NAME = "com.tange.ai/rapid_kit_example/method.channel/preference_store"

const PREFERENCES_NAME = "RapidKitExamplePreferences";

export default class PreferencesPlugin implements FlutterPlugin, AbilityAware {
  private methodChannel?: MethodChannel;
  private preferences: dataPreferences.Preferences | null = null;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL_NAME);

    try {
      let promise = dataPreferences.getPreferences(binding.getApplicationContext(), PREFERENCES_NAME);
      promise.then((object) => {
        this.preferences = object;
        Log.i(TAG, "[onAttachedToEngine] Succeeded in getting preferences.");
      }).catch((err: ESObject) => {
        Log.e(TAG, "[onAttachedToEngine] Failed to get preferences. code =" + err.code + ", message =" + err.message);
      })
    } catch (err) {
      Log.e(TAG, "[onAttachedToEngine] Failed to get preferences." + JSON.stringify(err));
    }

    let that = this;

    Log.i(
      TAG,
      "[onAttachedToEngine] context.preferencesDir = " + binding.getApplicationContext().preferencesDir);

    this.methodChannel.setMethodCallHandler({
      onMethodCall(call: MethodCall, result: MethodResult) {
        switch (call.method) {
          case "putPreferencesBool": {
            let key: string = call.argument("key")
            let value: boolean = call.argument("value")
            Log.i(
              TAG,
              "[putPreferencesBool] " + key + " -> " + value);
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            that.preferences?.put(key, value);
            that.preferences?.flush()
            result.success(null)
            break;
          }
          case "getPreferencesBool": {
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            let key: string = call.argument("key")
            let defaultValue: boolean = call.argument("defaultValue")
            let value: boolean = that.preferences?.getSync(key, defaultValue) as boolean;
            Log.i(
              TAG,
              "[getPreferencesBool] " + key + " -> " + value);
            result.success(value)
            break;
          }
          case "removePreferencesKey": {
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            let key: string = call.argument("key")
            Log.i(
              TAG,
              "[removePreferencesKey] " + key);
            if (that.preferences?.hasSync(key)) {
              that.preferences?.deleteSync(key)
            }
            that.preferences?.flush()
            result.success(null)
            break;
          }
          case "putPreferencesInt": {
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            let key: string = call.argument("key")
            let value: number = call.argument("value")
            that.preferences?.put(key, value);
            that.preferences?.flush()
            result.success(null)
            Log.i(
              TAG,
              "[putPreferencesInt] " + key + " -> " + value);
            break;
          }
          case "getPreferencesInt": {
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            let key: string = call.argument("key")
            let defaultValue: number = call.argument("defaultValue")
            let value: number = that.preferences?.getSync(key, defaultValue) as number;

            Log.i(
              TAG,
              "[getPreferencesInt] " + key + " -> " + value);

            result.success(value)
            break;
          }
          case "putPreferencesString": {
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            let key: string = call.argument("key")
            let value: string = call.argument("value")
            that.preferences?.put(key, value);
            that.preferences?.flush()
            Log.i(
              TAG,
              "[putPreferencesString] " + key + " -> <redacted:length=" + value.length + ">");


            result.success(null)
            break;
          }
          case "getPreferencesString": {
            if (that.preferences == null) {
              Log.e(TAG, "[notice] preferences is NULL")
            }
            let key: string = call.argument("key")
            let defaultValue: string = call.argument("defaultValue")
            let value: string = that.preferences?.getSync(key, defaultValue) as string;
            result.success(value)

            Log.i(
              TAG,
              "[getPreferencesString] " + key + " -> <redacted:length=" + value.length + ">");

            break;
          }
          default:
            Log.i(TAG, "[notice] notImplemented : " + call.method)
            result.notImplemented();
            break;
        }
      }
    })
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);

    try {
      let promise = this.preferences?.flush();
      promise?.then(() => {
        Log.i(TAG, "Succeeded in flushing.");
      }).catch((err: ESObject) => {
        Log.w(TAG, "Failed to flush." + JSON.stringify(err));
      })
    } catch (err) {
      Log.w(TAG, "Failed to flush." + JSON.stringify(err));
    }
  }

  getUniqueClassName(): string {
    return TAG;
  }


  onAttachedToAbility(binding: AbilityPluginBinding): void {
  }

  onDetachedFromAbility(): void {

  }
}
