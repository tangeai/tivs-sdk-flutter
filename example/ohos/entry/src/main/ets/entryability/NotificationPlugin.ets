import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { AbilityAware, Any,
  FlutterPlugin,
  MethodCall,
  MethodChannel,
  AbilityPluginBinding,
  NewWantListener,
  EventChannel,
} from '@ohos/flutter_ohos';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import notificationManager from '@ohos.notificationManager';
import Base from '@ohos.base';
import { AbilityConstant } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

const TAG = "NotificationPlugin"
const NOTIFICATION_ACTION = "com.tange.push.action_PUSH"
const METHOD_CHANNEL_NAME = "com.tange.ai/rapid_kit_example/method.channel/notification"
const EVENT_CHANNEL_NAME = "com.tange.ai/rapid_kit_example/event.channel/notification"

export default class NotificationPlugin implements FlutterPlugin, AbilityAware {

  private methodChannel?: MethodChannel;

  private eventChannel?: EventChannel;

  private eventSink?: EventSink;

  private pendingNotificationParameters: string | null = null

  private abilityPluginBinding?: AbilityPluginBinding;

  private newWantListener: NewWantListener = {
    onNewWant: (want: Want, launchParams: AbilityConstant.LaunchParam): void => {
      if (want.action == NOTIFICATION_ACTION) {
        this.pendingNotificationParameters = JSON.stringify(want.parameters)
        this.eventSink?.success(this.pendingNotificationParameters)
      }
    }
  };

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    binding.addOnNewWantListener(this.newWantListener)
    this.abilityPluginBinding = binding
    let want = binding.getAbility().launchWant
    if (want.action == NOTIFICATION_ACTION) {
      this.pendingNotificationParameters = JSON.stringify(want.parameters)
    }
  }

  onDetachedFromAbility(): void {
    this.abilityPluginBinding?.removeOnNewWantListener(this.newWantListener)
    this.abilityPluginBinding = undefined
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_NAME);

    let that = this;

    this.methodChannel.setMethodCallHandler({
      onMethodCall(call: MethodCall, result: MethodResult) {
        switch (call.method) {
          case "getPendingNotification":
            that.getPendingNotification(result);
            break;
          case "getPushServiceToken":
            that.requirePushServiceToken(result);
            break;
          case "isNotificationEnabled":
            that.isNotificationEnabled(result);
            break;
          case "requestNotificationEnabled":
            that.requestNotificationEnabled(result);
            break;
          default:
            result.notImplemented();
            break;
        }
      }
    })

    this.eventChannel.setStreamHandler({
      onListen(args: Any, events: EventSink): void {
        that.eventSink = events;
      },

      onCancel(args: Any): void {
        that.eventSink = undefined;
      }
    })
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
  }

  getUniqueClassName(): string {
    return "NotificationPlugin";
  }

  getPendingNotification(result: MethodResult) {
    if (this.pendingNotificationParameters != null && this.pendingNotificationParameters.length > 0) {
      result.success(this.pendingNotificationParameters)
      this.pendingNotificationParameters = ""
    } else {
      result.success("")
    }
  }

  async requirePushServiceToken(result: MethodResult) {
    try {
      const token = await pushService.getToken();
      if (token.trim().length === 0) {
        result.error('PUSH_TOKEN_EMPTY', 'Push Kit returned an empty token', null);
        return;
      }
      hilog.info(0x0000, TAG, 'Push token acquired');
      result.success(token);
    } catch (error) {
      const reason = error as Base.BusinessError;
      hilog.error(0x0000, TAG, 'getToken failed, code=%{public}d', reason.code);
      result.error(String(reason.code), reason.message, null);
    }
  }

  async requestNotificationEnabled(result: MethodResult) {
    try {
      if (!await notificationManager.isNotificationEnabled()) {
        const ability = this.abilityPluginBinding?.getAbility();
        if (!ability) {
          result.error('ABILITY_UNAVAILABLE', 'Notification permission requires a UIAbility', null);
          return;
        }
        await notificationManager.requestEnableNotification(ability.context);
      }
      result.success(null);
    } catch (error) {
      const reason = error as Base.BusinessError;
      hilog.error(0x0000, TAG, 'Notification permission failed, code=%{public}d', reason.code);
      result.error(String(reason.code), reason.message, null);
    }
  }

  isNotificationEnabled(result: MethodResult) {
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      console.info("isNotificationEnabled success, data: " + JSON.stringify(data));
      result.success(data)
    }).catch((err : Base.BusinessError) => {
      console.error(`isNotificationEnabled fail: ${JSON.stringify(err)}`);
      result.error(String(err.code), err.message, null)
    });
  }
}
