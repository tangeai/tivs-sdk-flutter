import UIKit
import Flutter
import UserNotifications
import Security
import RapidKit

private final class IOSScreenAwake {
  private var _owners = Set<String>()
  private var _previous_idle_timer_disabled: Bool?
  private var _foreground = true
  private var _observers = [NSObjectProtocol]()

  init() {
    for (notification, foreground) in [
      (UIApplication.didEnterBackgroundNotification, false),
      (UIApplication.didBecomeActiveNotification, true)
    ] {
      _observers.append(NotificationCenter.default.addObserver(
        forName: notification, object: nil, queue: .main
      ) { [weak self] _ in
        self?._foreground = foreground
        self?._apply_state(reason: foreground ? "foreground" : "background")
      })
    }
  }

  deinit {
    for observer in _observers { NotificationCenter.default.removeObserver(observer) }
    if let previous = _previous_idle_timer_disabled {
      UIApplication.shared.isIdleTimerDisabled = previous
    }
  }

  private func _apply_state(reason: String, owner: String = "none", enabled: String = "none") {
    let previous = _previous_idle_timer_disabled ?? UIApplication.shared.isIdleTimerDisabled
    if _foreground && !_owners.isEmpty {
      if _previous_idle_timer_disabled == nil {
        _previous_idle_timer_disabled = UIApplication.shared.isIdleTimerDisabled
      }
      UIApplication.shared.isIdleTimerDisabled = true
    } else if let previous = _previous_idle_timer_disabled {
      UIApplication.shared.isIdleTimerDisabled = previous
      _previous_idle_timer_disabled = nil
    }
    let awake = UIApplication.shared.isIdleTimerDisabled
    let restored = _previous_idle_timer_disabled == nil && awake == previous
    let stamp = Int64(Date().timeIntervalSince1970 * 1000)
    Logging.i("ScreenAwake", "[ScreenAwake] event=\(reason), owner=\(owner), enabled=\(enabled), foreground=\(_foreground), owners=\(_owners.count), screen_awake=\(awake), previous=\(previous), restored=\(restored), ts_epoch_ms=\(stamp)")
  }

  func set_enabled(owner: String, enabled: Bool) {
    if enabled {
      _owners.insert(owner)
    } else {
      _owners.remove(owner)
    }
    _apply_state(reason: "owner", owner: owner, enabled: String(enabled))
  }
}

@_silgen_name("SecTaskCreateFromSelf")
private func createSecurityTask(_ allocator: CFAllocator?) -> Unmanaged<CFTypeRef>?

@_silgen_name("SecTaskCopyValueForEntitlement")
private func copySecurityTaskEntitlement(
  _ task: CFTypeRef,
  _ entitlement: CFString,
  _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFTypeRef>?

private final class IOSPushBridge: NSObject, FlutterStreamHandler {
  static let shared = IOSPushBridge()

  private var eventSink: FlutterEventSink?
  private var registration: [String: Any]?
  private var pendingNotification: [String: Any]?

  func configure() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error {
        print("[IOSPushBridge] authorization failed, error=\(error.localizedDescription)")
      } else {
        print("[IOSPushBridge] authorization completed, granted=\(granted)")
      }
    }
    UIApplication.shared.registerForRemoteNotifications()
  }

  func handleRegistration(deviceToken: Data) {
    guard let isTest = currentAPNSEnvironment().map({ $0 == "development" }) else {
      print("[IOSPushBridge] missing or invalid aps-environment entitlement")
      return
    }
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    guard !token.isEmpty else { return }
    let value: [String: Any] = ["token": token, "channel": "apple", "isTest": isTest]
    registration = value
    eventSink?(["type": "registration", "registration": value])
    print("[IOSPushBridge] registration succeeded")
  }

  func handleRegistration(error: Error) {
    print("[IOSPushBridge] registration failed, error=\(error.localizedDescription)")
  }

  func handleNotification(_ userInfo: [AnyHashable: Any]) {
    let payload = Dictionary(uniqueKeysWithValues: userInfo.map { (String(describing: $0.key), $0.value) })
    pendingNotification = payload
    eventSink?(["type": "notification"])
  }

  func currentRegistration() -> [String: Any]? {
    registration
  }

  func takePendingNotification() -> String {
    guard let payload = pendingNotification,
          JSONSerialization.isValidJSONObject(payload),
          let data = try? JSONSerialization.data(withJSONObject: payload),
          let value = String(data: data, encoding: .utf8) else {
      return ""
    }
    pendingNotification = nil
    return value
  }

  func notificationEnabled(_ completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      completion(settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
    }
  }

  func requestNotificationEnabled() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func currentAPNSEnvironment() -> String? {
    guard let task = createSecurityTask(nil)?.takeRetainedValue(),
          let value = copySecurityTaskEntitlement(task, "aps-environment" as CFString, nil)?.takeRetainedValue(),
          let environment = value as? String,
          environment == "development" || environment == "production" else {
      return nil
    }
    return environment
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let _screen_awake = IOSScreenAwake()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    IOSPushBridge.shared.configure()
    return result
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    IOSPushBridge.shared.handleRegistration(deviceToken: deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    IOSPushBridge.shared.handleRegistration(error: error)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    IOSPushBridge.shared.handleNotification(notification.request.content.userInfo)
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    IOSPushBridge.shared.handleNotification(response.notification.request.content.userInfo)
    completionHandler()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let messenger = engineBridge.applicationRegistrar.messenger()
    FlutterMethodChannel(
      name: "com.tange.ai/rapid_kit_example/method.channel/screen_awake",
      binaryMessenger: messenger
    ).setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
            let owner = arguments["owner"] as? String, !owner.isEmpty,
            let enabled = arguments["enabled"] as? Bool, let self = self else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid screen awake owner", details: nil))
        return
      }
      self._screen_awake.set_enabled(owner: owner, enabled: enabled)
      result(nil)
    }
    let preferenceChannel = FlutterMethodChannel(name: "com.tange.ai/rapid_kit_example/method.channel/preference_store",
                                                 binaryMessenger: messenger)

    let notificationChannel = FlutterMethodChannel(
      name: "com.tange.ai/rapid_kit_example/method.channel/notification",
      binaryMessenger: messenger
    )
    notificationChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getPushRegistration":
        result(IOSPushBridge.shared.currentRegistration())
      case "getPendingNotification":
        result(IOSPushBridge.shared.takePendingNotification())
      case "isNotificationEnabled":
        IOSPushBridge.shared.notificationEnabled { enabled in
          DispatchQueue.main.async { result(enabled) }
        }
      case "requestNotificationEnabled":
        IOSPushBridge.shared.requestNotificationEnabled()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    FlutterEventChannel(
      name: "com.tange.ai/rapid_kit_example/event.channel/notification",
      binaryMessenger: messenger
    ).setStreamHandler(IOSPushBridge.shared)

    preferenceChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      let arguments = call.arguments as? [String: Any]
      let key = arguments?["key"] as? String

      switch call.method {
      case "putPreferencesInt":
        if let key = key, let value = arguments?["value"] as? Int {
          UserDefaults.standard.set(value, forKey: key)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for putPreferencesInt", details: nil))
        }
      case "getPreferencesInt":
        if let key = key {
          let value = UserDefaults.standard.integer(forKey: key)
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for getPreferencesInt", details: nil))
        }
      case "putPreferencesString":
        if let key = key, let value = arguments?["value"] as? String {
          UserDefaults.standard.set(value, forKey: key)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for putPreferencesString", details: nil))
        }
      case "getPreferencesString":
        if let key = key {
          let value = UserDefaults.standard.string(forKey: key) ?? arguments?["defaultValue"] as? String ?? ""
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for getPreferencesString", details: nil))
        }
      case "putPreferencesBool":
        if let key = key, let value = arguments?["value"] as? Bool {
          UserDefaults.standard.set(value, forKey: key)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for putPreferencesBool", details: nil))
        }
      case "getPreferencesBool":
        if let key = key {
          let value = UserDefaults.standard.bool(forKey: key)
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for getPreferencesBool", details: nil))
        }
      case "removePreferencesKey":
        if let key = key {
          UserDefaults.standard.removeObject(forKey: key)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for removePreferencesKey", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
