import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  SurfaceTextureEntry,
  TextureRegistry,
} from '@ohos/flutter_ohos';
import fs from '@ohos.file.fs';
import wifiManager from '@ohos.wifiManager';
import UIAbility from '@ohos.app.ability.UIAbility'
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { Rapid } from 'rapid_kit_foundation'
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import * as rapidBle from './RapidKitBleContext'
import * as rapidPermission from './RapidKitPermission'
import { Captcha, CaptchaConfiguration, CaptchaListener, CloseType } from '@yidun/captcha';
import { window } from '@kit.ArkUI';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'RapidKitPlugin'
const RAPID_KIT_PLATFORM_CHANNEL = "com.tange.ai/rapid_kit/method.channel"
const AUDIO_PERMISSION: Array<Permissions> = ['ohos.permission.MICROPHONE']
const LOCATION_PERMISSION: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']
const BLUETOOTH_PERMISSION: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH', 'ohos.permission.USE_BLUETOOTH', 'ohos.permission.DISCOVER_BLUETOOTH']

const RESULT_PERMISSION_GRANTED = 1
const RESULT_PERMISSION_DENIED = 2
const TEXTURE_BACKGROUND_COLOR: number = 0xFF000000
let capturePathSequence: number = 0

interface PlayerTextureBinding {
  textureId: number;
  playerPtr: number;
  containerWidth: number;
  containerHeight: number;
  nativeWindowId: number;
  entry: SurfaceTextureEntry;
}

export default class RapidKitPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private binding: FlutterPluginBinding | null = null;
  private channel: MethodChannel | null = null;
  private textureRegistry: TextureRegistry | null = null;
  private readonly playerPtrToCapturedPicturePath: Map<number, string> = new Map<number, string>();
  private readonly playerTexturesByPtr: Map<number, PlayerTextureBinding> = new Map<number, PlayerTextureBinding>();
  private readonly playerTexturesById: Map<number, PlayerTextureBinding> = new Map<number, PlayerTextureBinding>();
  private ability: UIAbility | null = null;
  private readonly rapidKitBleContext: rapidBle.RapidKitBleContext = new rapidBle.RapidKitBleContext();

  private uiContext: UIContext | null = null;

  private robotCheckResult: MethodResult | null = null;

  private completeRobotCheck(result: string): void {
    const pendingResult = this.robotCheckResult
    this.robotCheckResult = null
    pendingResult?.success(result)
  }

  private listener: CaptchaListener = {
    onValidate: (result: string, validate: string, _msg: string, _captchaType:string, _errorValidate:string) => {
      Log.i(TAG, `[accountRobotCheck] captcha validated, result=${result}`)
      if (result === "true") {
        this.completeRobotCheck(validate)
      } else {
        this.completeRobotCheck("ERROR:UNKNOWN")
      }
    },
    onError: (code: number, msg: string) => {
      Log.i(TAG, `[accountRobotCheck] captcha failed, code=${code}, message=${msg}`)
      this.completeRobotCheck(`ERROR:${code}:${msg}`)
    },
    onCaptchaShow: () => {
      Log.i(TAG, "[accountRobotCheck] captcha shown")
    },
    onClose:(closeType:CloseType)=>{
      Log.i(TAG, `[accountRobotCheck] captcha closed, type=${closeType}`)
      if (closeType !== CloseType.VERIFY_SUCCESS_CLOSE) {
        this.completeRobotCheck("ERROR:CLOSED")
      }
    }
  }

  constructor() {
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility()
    let that = this
  }

  onDetachedFromAbility(): void {
    this.ability = null
  }

  getUniqueClassName(): string {
    return TAG
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Rapid.initialize();
    this.binding = binding
    this.channel = new MethodChannel(binding.getBinaryMessenger(), RAPID_KIT_PLATFORM_CHANNEL)
    this.channel.setMethodCallHandler(this)
    this.textureRegistry = binding.getTextureRegistry()

  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    let textureIds = Array.from(this.playerTexturesById.keys())
    textureIds.forEach((textureId: number) => this.disposePlayerTexture(textureId))
    this.playerTexturesByPtr.clear()
    this.playerTexturesById.clear()
    this.textureRegistry = null
    this.channel = null
    this.binding = null
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    let that = this
    if (call.method == "accountRobotCheck") {
      if (this.robotCheckResult != null) {
        Log.i(TAG, "[accountRobotCheck] rejected duplicate request")
        result.success("ERROR:ALREADY_IN_PROGRESS")
        return
      }
      const ability = this.ability
      if (ability == null) {
        Log.i(TAG, "[accountRobotCheck] ability unavailable")
        result.success("ERROR:ABILITY_UNAVAILABLE")
        return
      }
      this.robotCheckResult = result;
      let configuration: CaptchaConfiguration = new CaptchaConfiguration();
      configuration.setCaptchaId("f9c76200db674493a1319a4a3b6cb99e");
      configuration.setListener(this.listener);
      ability.context.windowStage.getMainWindow().then((window) => {
        that.uiContext = window.getUIContext()
        const captcha = Captcha.getInstance()
        Log.i(TAG, "[accountRobotCheck] initializing captcha")
        captcha.init(that.uiContext!, configuration);
        captcha.showCaptcha();
      }).catch((error: BusinessError) => {
        Log.i(TAG, `[accountRobotCheck] setup failed, code=${error.code}, message=${error.message}`)
        that.completeRobotCheck(`ERROR:${error.code}:${error.message}`)
      })
    } else if (call.method == "writeBluetoothData") {
      this.rapidKitBleContext.write(call.args as Uint8Array, ret => {
        result.success(ret)
      })
    } else if (call.method == "connectBluetoothDevice") {
      let mac: string = call.argument("mac")
      let characteristics: Array<string> = call.argument('characteristics')
      this.rapidKitBleContext.connect(mac, characteristics, ret => {
        result.success(ret);
      });
    } else if (call.method == "disconnectBluetoothDevice") {
      this.rapidKitBleContext.disconnect()
      result.success(null);
    }else if (call.method == "stopBluetoothDiscovery") {
      this.rapidKitBleContext.stopDiscovery()
      result.success(null);
    } else if (call.method == "getBluetoothDevices") {
      result.success(this.rapidKitBleContext.nearbyDevices());
    } else if (call.method == "acquireBluetoothPermission") {
      this.acquireRuntimePermission(BLUETOOTH_PERMISSION, result)
    } else if (call.method == "isBluetoothPermissionGranted") {
      this.rapidKitBleContext.permissionGranted(granted => {
        result.success(granted)
      })
    } else if (call.method == "startBluetoothDiscovery") {
      this.rapidKitBleContext.startDiscovery()
      result.success(null)
    } else if (call.method == "isBluetoothEnabled") {
      result.success(this.rapidKitBleContext.isEnabled())
    } else if (call.method == "exportCapturedPicture") {
      this.onExportCapturedImage(call, result)
    } else if (call.method == "exportCapturedVideo") {
      this.onExportCapturedVideo(call, result)
    } else if (call.method == "attachMediaChat") {
      let ptr: number = call.argument("mediaChatPtr")
      Rapid.bindingAinToMediaChat(ptr)
      result.success(true)
    } else if (call.method == "requireWriteableCachePath") {
      capturePathSequence += 1
      let timestamp = Date.now().toString()
      let path: string = this.binding!.getApplicationContext().cacheDir + "/rapid_capture" + timestamp + "_" + capturePathSequence + "_"
      result.success(path)
    } else if (call.method == "requestFileAccessPermission") {
      result.success(null)
    } else if (call.method == "isFileAccessPermissionGranted") {
      result.success(true)
    } else if (call.method == "launchWiFiSettings") {
      let want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility'
      }
      this.ability?.context.startAbility(want).then(() => {
        result.success(true)
      }).catch((err: BusinessError) => {
        Log.i(TAG, "[launchWiFiSettings] err = " + err)
        result.success(false)
      })
    } else if (call.method == "requireLocationPermission") {
      this.acquireRuntimePermission(LOCATION_PERMISSION, result)
    } else if (call.method == "isLocationPermissionRequired") {
      rapidPermission.checkAccessToken(LOCATION_PERMISSION[0]).then((grantStatus) => {
        let granted: boolean = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        result.success(granted)
      })
    } else if (call.method == "currentWifi") {
      wifiManager.getLinkedInfo().then((info) => {
        result.success(info.ssid)
      })
    } else if (call.method == "requireMicrophone") {
      this.acquireRuntimePermission(AUDIO_PERMISSION, result)
    } else if (call.method == "isMicrophoneRequired") {
      rapidPermission.checkAccessToken(AUDIO_PERMISSION[0]).then((grantStatus) => {
        let granted: boolean = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        result.success(granted)
      })
    } else if (call.method == "requireLoggingCacheDirectory") {
      let path: string = this.binding!.getApplicationContext().cacheDir + "/rapid_logging"
      let exist = fs.accessSync(path, fs.AccessModeType.EXIST)
      if (!exist) {
        fs.mkdirSync(path)
      }
      result.success(path)
    } else if (call.method == "attachPlayerTexture") {
      let ptr: number = call.argument("playerPtr")
      let containerWidth: number = call.argument("containerWidth")
      let containerHeight: number = call.argument("containerHeight")
      let binding = this.ensurePlayerTexture(ptr, -1, containerWidth, containerHeight, false)
      if (binding == null) {
        result.error("texture_binding_failed", "Failed to attach player texture", null)
      } else {
        result.success(binding.textureId)
      }
    } else if (call.method == "ensurePlayerTexture") {
      let ptr: number = call.argument("playerPtr")
      let currentTextureId: number = call.argument("currentTextureId")
      let containerWidth: number = call.argument("containerWidth")
      let containerHeight: number = call.argument("containerHeight")
      let forceRecreate: boolean = call.argument("forceRecreate")
      let binding = this.ensurePlayerTexture(
        ptr,
        currentTextureId,
        containerWidth,
        containerHeight,
        forceRecreate,
      )
      if (binding == null) {
        result.error("texture_binding_failed", "Failed to ensure player texture", null)
      } else {
        result.success(binding.textureId)
      }
    } else if (call.method == "detachPlayerTexture") {

      let textureId: number = call.argument("textureId")

      Log.i(TAG, "[detachPlayerTexture] textureId = " + textureId)

      this.disposePlayerTexture(textureId)

      Log.i(TAG, "[detachPlayerTexture] finish unregisterTexture")

      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  private ensurePlayerTexture(
    playerPtr: number,
    currentTextureId: number,
    containerWidth: number,
    containerHeight: number,
    forceRecreate: boolean,
  ): PlayerTextureBinding | null {
    let existing = this.playerTexturesByPtr.get(playerPtr)
    let canReuse = existing != null &&
      !forceRecreate &&
      existing.nativeWindowId > 0 &&
      (currentTextureId < 0 || existing.textureId == currentTextureId)
    if (canReuse) {
      Log.i(TAG, "[ensurePlayerTexture] reuse textureId=" + existing!.textureId + ", playerPtr=" + playerPtr)
      return existing!
    }

    let replacement = this.createPlayerTexture(playerPtr, containerWidth, containerHeight)
    if (replacement == null) {
      Log.e(TAG, "[ensurePlayerTexture] failed, playerPtr=" + playerPtr + ", currentTextureId=" + currentTextureId)
      return null
    }

    if (existing != null && existing.textureId != replacement.textureId) {
      this.disposePlayerTexture(existing.textureId)
    } else if (currentTextureId >= 0 && currentTextureId != replacement.textureId) {
      this.disposePlayerTexture(currentTextureId)
    }

    Log.i(TAG, "[ensurePlayerTexture] ready textureId=" + replacement.textureId +
      ", playerPtr=" + playerPtr + ", forceRecreate=" + forceRecreate)
    return replacement
  }

  private createPlayerTexture(
    playerPtr: number,
    containerWidth: number,
    containerHeight: number,
  ): PlayerTextureBinding | null {
    let registry = this.textureRegistry
    if (registry == null) {
      Log.e(TAG, "[createPlayerTexture] textureRegistry is null")
      return null
    }

    let textureId = registry.getTextureId()
    let entry = registry.registerTexture(textureId)
    let nativeWindowId = entry.getNativeWindowId()
    if (nativeWindowId <= 0) {
      Log.e(TAG, "[createPlayerTexture] invalid nativeWindowId, textureId=" + textureId)
      registry.unregisterTexture(textureId)
      return null
    }

    registry.setTextureBackGroundColor(textureId, TEXTURE_BACKGROUND_COLOR)
    Rapid.bindingMediaPlayerSDL(
      nativeWindowId.toString(),
      playerPtr,
      containerWidth,
      containerHeight,
    )

    let binding: PlayerTextureBinding = {
      textureId: textureId,
      playerPtr: playerPtr,
      containerWidth: containerWidth,
      containerHeight: containerHeight,
      nativeWindowId: nativeWindowId,
      entry: entry,
    }
    this.playerTexturesByPtr.set(playerPtr, binding)
    this.playerTexturesById.set(textureId, binding)
    return binding
  }

  private disposePlayerTexture(textureId: number): void {
    let binding = this.playerTexturesById.get(textureId)
    if (binding != null) {
      this.playerTexturesById.delete(textureId)
      if (this.playerTexturesByPtr.get(binding.playerPtr)?.textureId == textureId) {
        this.playerTexturesByPtr.delete(binding.playerPtr)
      }
    }
    this.textureRegistry?.unregisterTexture(textureId)
  }

  onExportCapturedImage(call: MethodCall, result: MethodResult) {
    let path: string = call.argument("cachePath")
    Log.i(TAG, "[onExportCapturedImage] path = " + path)
    let exist = fs.accessSync(path, fs.AccessModeType.EXIST)
    Log.i(TAG, "[onExportCapturedImage] exist = " + exist)
    if (exist) {
      let helper = photoAccessHelper.getPhotoAccessHelper(this.ability!.context)
      let timestamp = Date.now().toString()
      helper.showAssetsCreationDialog([path], [{
        title: "captured_" + timestamp,
        fileNameExtension: "jpg",
        photoType: photoAccessHelper.PhotoType.IMAGE
      }]).then((paths: Array<string>) => {
        Log.i(TAG, "[onExportCapturedImage] granted = " + paths[0])
        const desFile = fs.openSync(paths[0], fs.OpenMode.WRITE_ONLY)
        const srcFile = fs.openSync(path, fs.OpenMode.READ_ONLY)
        fs.copyFileSync(srcFile.fd, desFile.fd)
        fs.closeSync(srcFile)
        fs.closeSync(desFile)
        fs.unlinkSync(path)
        result.success(true)
      }).catch((reason: BusinessError) => {
        Log.i(TAG, "[onExportCapturedImage] failed = " + reason)
        result.success(false)
      })

    } else {
      result.success(false)
    }
  }

  acquireRuntimePermission(permissions: Permissions[], result: MethodResult) {
    rapidPermission.checkAccessToken(LOCATION_PERMISSION[0]).then((grantStatus) => {
      Log.i(TAG, "[acquireRuntimePermission] grantStatus = " + grantStatus)
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        Log.i(TAG, "[acquireRuntimePermission] PERMISSION_GRANTED")
        result.success(RESULT_PERMISSION_GRANTED)
      } else if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        Log.i(TAG, "[acquireRuntimePermission] try ...")
        let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
        atManager.requestPermissionsFromUser(this.ability!.context, permissions).then((ar) => {
          Log.i(TAG, "[acquireRuntimePermission] authResults.permissions = " + ar.permissions)
          Log.i(TAG, "[acquireRuntimePermission] authResults.authResults = " + ar.authResults)
          if (ar.authResults.length > 0 && ar.authResults[0] < 0) {
            result.success(RESULT_PERMISSION_DENIED)
          } else if (ar.authResults.length > 0 && ar.authResults[0] >= 0) {
            result.success(RESULT_PERMISSION_GRANTED)
          } else {
            result.success(RESULT_PERMISSION_DENIED)
          }
        })
      }
    })
  }

  onExportCapturedVideo(call: MethodCall, result: MethodResult) {
    let path: string = call.argument("cachePath")
    let exist = fs.accessSync(path, fs.AccessModeType.EXIST)
    if (exist) {
      let helper = photoAccessHelper.getPhotoAccessHelper(this.ability!.context)
      let timestamp = Date.now().toString()
      helper.showAssetsCreationDialog([path], [{
        title: "captured_" + timestamp,
        fileNameExtension: "mp4",
        photoType: photoAccessHelper.PhotoType.VIDEO
      }]).then((paths: Array<string>) => {
        Log.i(TAG, "[onExportCapturedImage] granted = " + paths[0])
        const desFile = fs.openSync(paths[0], fs.OpenMode.WRITE_ONLY)
        const srcFile = fs.openSync(path, fs.OpenMode.READ_ONLY)
        fs.copyFileSync(srcFile.fd, desFile.fd)
        fs.closeSync(srcFile)
        fs.closeSync(desFile)
        fs.unlinkSync(path)
        result.success(true)
      }).catch((reason: BusinessError) => {
        Log.i(TAG, "[onExportCapturedImage] failed = " + reason)
        result.success(false)
      })
    } else {
      result.success(false)
    }
  }
}
