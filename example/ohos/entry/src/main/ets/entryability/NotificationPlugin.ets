import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { AbilityAware, Any,
  FlutterPlugin,
  Log,
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
import UIAbility from '@ohos.app.ability.UIAbility'
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

  requirePushServiceToken(result: MethodResult) {
    pushService.getToken().then((token) => {
      result.success(token);
    }).catch((reason: Base.BusinessError) => {
      result.success(reason.code + "," + reason.message);
    })
  }

  requestNotificationEnabled(result: MethodResult) {
    result.success(null);
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      console.info("isNotificationEnabled success, data: " + JSON.stringify(data));
      if(!data){
        notificationManager.requestEnableNotification().then(() => {
          console.info(`[ANS] requestEnableNotification success`);
        }).catch((err : Base.BusinessError) => {
          if(1600004 == err.code){
            console.info(`[ANS] requestEnableNotification refused`);
          } else {
            console.error(`[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
          }
        });
      }
    }).catch((err : Base.BusinessError) => {
      console.error(`isNotificationEnabled fail: ${JSON.stringify(err)}`);
    });
  }

  isNotificationEnabled(result: MethodResult) {
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      console.info("isNotificationEnabled success, data: " + JSON.stringify(data));
      result.success(data)
    }).catch((err : Base.BusinessError) => {
      console.error(`isNotificationEnabled fail: ${JSON.stringify(err)}`);
      result.success(false)
    });
  }
}

