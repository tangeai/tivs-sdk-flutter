import Cocoa
import RapidKit
import FlutterMacOS
import AVFoundation
import CoreWLAN
import CoreLocation

public class RapidKitPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    
    private var flutterTextureRegistry: FlutterTextureRegistry!
    private var textureEntryMap: [Int64: RapidTexture] = [:]
    private var playerPtrToCapturedPicturePath = [Int64: String]()
    private let locationManager = CLLocationManager()
    
    private lazy var bleContext: RapidKitBleContext = {
        return RapidKitBleContext()
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.tange.ai/rapid_kit/method.channel", binaryMessenger: registrar.messenger)
        let instance = RapidKitPlugin()
        instance.flutterTextureRegistry = registrar.textures
        registrar.addMethodCallDelegate(instance, channel: channel)
        RAPID_Initialize()
    }
    
    public override init() {
        super.init()
        locationManager.delegate = self
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            
        case "connectBluetoothDevice":
            connectBluetoothDevice(call: call, result: result)
            
        case "disconnectBluetoothDevice":
            disconnectBluetoothDevice(call: call, result: result)

        case "writeBluetoothData":
            writeBluetoothData(call: call, result: result)
            
        case "startBluetoothDiscovery":
            startBleDiscovery(result: result)
            
        case "stopBluetoothDiscovery":
            bleContext.stopDiscovery()
            result(nil)
            
        case "getBluetoothDevices":
            result(bleContext.getNearbyDevices())
            
        case "acquireBluetoothPermission":
            acquireBluetoothPermission(result: result)
            
        case "isBluetoothEnabled":
            checkBluetoothStatus(result: result)
            
        case "isBluetoothPermissionGranted":
            result(bleContext.permissionGranted())
            
        case "requireLoggingCacheDirectory":
            requireLoggingCacheDirectory(result: result)
            
        case "requireWriteableCachePath":
            requireWriteableCachePath(result: result)
            
        case "requestFileAccessPermission":
            requestFileAccessPermission(result: result)
            
        case "isFileAccessPermissionGranted":
            isFileAccessPermissionGranted(result: result)
            
        case "exportCapturedPicture":
            exportCapturedPicture(call: call, result: result)
            
        case "exportCapturedVideo":
            exportCapturedVideo(call: call, result: result)
            
        case "launchWiFiSettings":
            openWiFiSettings(result: result)
            
        case "requireLocationPermission":
            requestLocationPermission()
            result(isLocationPermissionRequired())
            
        case "isLocationPermissionRequired":
            result(isLocationPermissionRequired())
            
        case "currentWifi":
            result(currentWifi())
            
        case "attachMediaChat":
            attachMediaChat(call: call, result: result)
            
        case "requireMicrophone":
            requireMicrophone(call: call, result: result)
            
        case "isMicrophoneRequired":
            isMicrophoneRequired(call: call, result: result)
            
        case "attachPlayerTexture":
            attachPlayerTexture(call: call, result: result)
            
        case "detachPlayerTexture":
            detachPlayerTexture(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func openWiFiSettings(result: @escaping FlutterResult) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network") {
            if NSWorkspace.shared.open(url) {
                print("Successfully opened Network preferences")
            } else {
                print("Failed to open Network preferences")
            }
        }
    }
    
    private func requestFileAccessPermission(result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        let desktopDir: URL
        do {
            desktopDir = try fileManager.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let testFileURL = desktopDir.appendingPathComponent("permission_test.txt")
            try "Test".write(to: testFileURL, atomically: true, encoding: .utf8)
            try fileManager.removeItem(at: testFileURL)
            NSLog("Info: Desktop access permission requested")
        } catch {
            NSLog("Error: Failed to request desktop access permission - \(error.localizedDescription)")
        }
        result(nil)
    }
    
    private func isFileAccessPermissionGranted(result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        let desktopDir: URL
        do {
            desktopDir = try fileManager.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let testFileURL = desktopDir.appendingPathComponent("permission_test.txt")
            
            // Try to write a test file to check if we have permission
            try "Test".write(to: testFileURL, atomically: true, encoding: .utf8)
            
            // Remove the test file after writing
            try fileManager.removeItem(at: testFileURL)
            
            // If we can write and delete the test file, permission is granted
            result(true)
        } catch {
            // If any error occurs, we assume permission isn't granted
            NSLog("Error: Failed to check desktop access permission - \(error.localizedDescription)")
            result(false)
        }
    }
    
    private func requireLoggingCacheDirectory(result: @escaping FlutterResult) {
        let path = generateSandboxCacheDirectory(name: "rapid_logging") ?? ""
        result(path)
    }
    
    private func generateSandboxCacheDirectory(name: String) -> String? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        
        let directoryURL = cachesDirectory.appendingPathComponent(name, isDirectory: true)
        
        do {
            if !FileManager.default.fileExists(atPath: directoryURL.path) {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            return directoryURL.path
        } catch {
            print("Error creating or accessing the application support directory: \(error)")
            return nil
        }
    }
    
    private func connectBluetoothDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let identifier = args["mac"] as? String else {
            result(false)
            return
        }
        bleContext.connect(
            identifier: identifier,
            preferredCharacteristics: args["characteristics"] as? [String]
        ) { connected in
            result(connected)
        }
    }

    private func disconnectBluetoothDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        bleContext.disconnect(identifier: args?["mac"] as? String ?? "")
        result(nil)
    }

    private func writeBluetoothData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let data = call.arguments as? FlutterStandardTypedData else {
            result(false)
            return
        }
        bleContext.write(data: data.data) { written in
            result(written)
        }
    }
    
    private func exportCapturedPicture(call: FlutterMethodCall, result: @escaping FlutterResult) {
         guard let args = call.arguments as? [String: Any],
              let srcPath = args["cachePath"] as? String else {
            NSLog("Error: Could not extract cachePath")
            result(false)
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: srcPath) {
            do {
                let desktopDir = try fileManager.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                let timestamp = dateFormatter.string(from: Date())
                let destFileName = "\(timestamp).jpg"
                let destPath = desktopDir.appendingPathComponent(destFileName)
                
                if !fileManager.fileExists(atPath: destPath.path) {
                    try fileManager.copyItem(atPath: srcPath, toPath: destPath.path)
                    result(true)
                } else {
                    NSLog("Error: File already exists on Desktop")
                    result(false)
                }
            } catch {
                NSLog("Error: Failed to copy file to Desktop - \(error.localizedDescription)")
                result(false)
            }
        } else {
            NSLog("Error: Source file does not exist")
            result(false)
        }
        
        do {
            try fileManager.removeItem(atPath: srcPath)
        } catch {
            NSLog("Error: Failed to delete source file - \(error.localizedDescription)")
        }
    }
    
    private func exportCapturedVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let srcPath = args["cachePath"] as? String else {
            NSLog("Error: Could not extract cachePath")
            result(false)
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: srcPath) {
            do {
                let desktopDir = try fileManager.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                let timestamp = dateFormatter.string(from: Date())
                let destFileName = "\(timestamp).mp4"
                let destPath = desktopDir.appendingPathComponent(destFileName)
                
                if !fileManager.fileExists(atPath: destPath.path) {
                    try fileManager.copyItem(atPath: srcPath, toPath: destPath.path)
                    NSLog("Info: File successfully copied to Desktop")
                    result(true)
                } else {
                    NSLog("Error: File already exists on Desktop")
                    result(false)
                }
            } catch {
                NSLog("Error: Failed to copy file to Desktop - \(error.localizedDescription)")
                result(false)
            }
        } else {
            NSLog("Error: Source file does not exist")
            result(false)
        }
        
        do {
            try fileManager.removeItem(atPath: srcPath)
            NSLog("Info: Source file deleted successfully")
        } catch {
            NSLog("Error: Failed to delete source file - \(error.localizedDescription)")
        }
    }
    
    private func generateSandboxFilePath() -> String? {
        if let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let fileName = "rapid_captured_\(Int(Date().timeIntervalSince1970)).jpg"
            return applicationSupportDirectory.appendingPathComponent(fileName).path
        }
        return nil
    }
    
    private func requireWriteableCachePath(result: @escaping FlutterResult) {
        let path = generateSandboxFilePath() ?? ""
        result(path)
    }
    
    private func generateDesktopFilePath() -> String? {
        let desktopDir = NSHomeDirectory() + "/Desktop"
        let fileName = "rapid_captured_\(Int(Date().timeIntervalSince1970)).jpg"
        return "\(desktopDir)/\(fileName)"
    }
    
    private func requestLocationPermission() {
        _ = CLLocationManager.authorizationStatus()
        if #available(macOS 10.15, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Not needed for macOS versions before 10.15
        }
    }
    
    private func isLocationPermissionRequired() -> Bool {
        if #available(macOS 10.15, *) {
            let status = CLLocationManager.authorizationStatus()
            return status == .authorized || status == .authorizedAlways
        } else {
            return true
        }
    }
    
    private func checkBluetoothStatus(result: @escaping FlutterResult) {
        bleContext.checkEnabled { enabled in
            result(enabled)
        }
    }
    
    private func startBleDiscovery(result: @escaping FlutterResult) {
        bleContext.startDiscovery()
        result(nil)
    }
    
    private func acquireBluetoothPermission(result: @escaping FlutterResult) {
        bleContext.acquirePermission { permission in
            result(permission)
        }
    }
    
    private func currentWifi() -> String {
        return CWWiFiClient.shared().interface(withName: nil)?.ssid() ?? ""
    }
    
    private func requireMicrophone(call: FlutterMethodCall, result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            result(nil)
        }
    }
    
    private func isMicrophoneRequired(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            result(true)
        case .denied, .restricted, .notDetermined:
            result(false)
        @unknown default:
            result(false)
        }
    }
    
    
    private func attachMediaChat(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let chatPtr = args["mediaChatPtr"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Could not extract mediaChatPtr", details: nil))
            return
        }

        let mediaChatPtr: uintptr_t = uintptr_t(chatPtr)
        let bindingResult = RAPID_MediaChat_AttachAin(mediaChatPtr)

        if bindingResult != 1 {
            result(FlutterError(
                code: "BINDING_FAILED",
                message: "Failed to bind ain to MediaChat",
                details: "result=\(bindingResult)"
            ))
            return
        }

        result(true)
    }
    
    
    private func attachPlayerTexture(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerPtr = args["playerPtr"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Could not extract playerPtr", details: nil))
            return
        }
        
        let rapidTexture = RapidTexture()
        let textureId = flutterTextureRegistry.register(rapidTexture)
        
        rapidTexture.textureId = textureId
        rapidTexture.flutterTextureRegistry = flutterTextureRegistry
        
        let (callback, context) = rapidTexture.getCFunctionPointer()
        if let callback = callback, let context = context {
            let mediaPlayerPtr: uintptr_t = uintptr_t(playerPtr)
            
            let bindingResult = RAPID_SDL_Vout_PixelBuffer_Binding(mediaPlayerPtr, callback, context)
            if bindingResult == 0 {
                fatalError("Error: Failed to bind callback, result: \(bindingResult)")
            }
        }
        
        if textureId <= 0 {
            fatalError("[Rapid-Bridging][iOS] Failed registering texture to Flutter registry")
        }
        
        // Store the texture in the map
        textureEntryMap[textureId] = rapidTexture
        
        result(textureId)
    }
    
    private func detachPlayerTexture(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let textureId = args["textureId"] as? Int64 else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Could not extract textureId", details: nil))
            return
        }
        
        flutterTextureRegistry.unregisterTexture(textureId)
        
        if let rapidTexture = textureEntryMap.removeValue(forKey: textureId) {
            rapidTexture.dispose()
        } 
        
        result(nil)
    }
    
}
