import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    let controller: FlutterViewController = mainFlutterWindow!.contentViewController as! FlutterViewController
    let preferenceChannel = FlutterMethodChannel(name: "com.tange.ai/rapid_kit_example/method.channel/preference_store",
                                                 binaryMessenger: controller.engine.binaryMessenger)

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
          let value = UserDefaults.standard.object(forKey: key) as? Int ?? arguments?["defaultValue"] as? Int ?? 0
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
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
