import Flutter
import UIKit
import RapidKit
import AVFoundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import NetworkExtension
import Photos
import Foundation
import SystemConfiguration
import CoreBluetooth
import VerifyCode

let METHOD_CHANNEL_NAME = "com.tange.ai/rapid_kit/method.channel"

let METHOD_ATTACH_PLAYER_TEXTURE = "attachPlayerTexture"
let METHOD_DETACH_PLAYER_TEXTURE = "detachPlayerTexture"
let PARAM_PLAYER_PTR = "playerPtr"

private struct RapidKitBleCharacteristicSelector {
    private static let bluetoothBaseUuidSuffix = "-0000-1000-8000-00805f9b34fb"

    // Source snapshot: Bluetooth SIG assigned_numbers/uuids/service_uuids.yaml through 0x1860.
    private static let sigAssignedServiceUuidRanges = [
        0x1800...0x180a,
        0x180d...0x1816,
        0x1818...0x1829,
        0x183a...0x1840,
        0x1843...0x1860
    ]

    enum SelectionReason: String {
        case preferred
        case automatic
    }

    struct Candidate {
        let uuid: String
        let properties: CBCharacteristicProperties
        let serviceUuid: String
        let index: Int
    }

    struct Selection {
        let candidate: Candidate
        let score: Int
        let reason: SelectionReason
    }

    static func select(candidates: [Candidate], preferredUuids: [String]?) -> Selection? {
        let preferred = Set((preferredUuids ?? []).map { normalizeUuid($0) })
        var preferredSelection: Selection?
        var automaticSelection: Selection?

        for candidate in candidates {
            let score = calculateScore(candidate.properties)
            if score <= 0 {
                continue
            }

            let normalizedUuid = normalizeUuid(candidate.uuid)
            if preferred.contains(normalizedUuid) && score > (preferredSelection?.score ?? -1) {
                preferredSelection = Selection(candidate: candidate, score: score, reason: .preferred)
            }
            if !isSigAssignedServiceUuid(candidate.serviceUuid) && score > (automaticSelection?.score ?? -1) {
                automaticSelection = Selection(candidate: candidate, score: score, reason: .automatic)
            }
        }

        return preferredSelection ?? automaticSelection
    }

    static func isSigAssignedServiceUuid(_ uuid: String) -> Bool {
        let normalizedUuid = normalizeUuid(uuid)
        guard normalizedUuid.count == 36,
              normalizedUuid.hasPrefix("0000"),
              normalizedUuid.hasSuffix(bluetoothBaseUuidSuffix),
              let shortUuid = Int(normalizedUuid.dropFirst(4).prefix(4), radix: 16) else {
            return false
        }

        return sigAssignedServiceUuidRanges.contains { $0.contains(shortUuid) }
    }

    private static func normalizeUuid(_ uuid: String) -> String {
        let normalizedUuid = uuid.lowercased()
        switch normalizedUuid.count {
        case 4:
            return "0000\(normalizedUuid)\(bluetoothBaseUuidSuffix)"
        case 8:
            return "\(normalizedUuid)\(bluetoothBaseUuidSuffix)"
        default:
            return normalizedUuid
        }
    }

    static func calculateScore(_ properties: CBCharacteristicProperties) -> Int {
        guard supportsWrite(properties) else {
            return 0
        }

        var score = 100
        if properties.contains(.notify) {
            score += 50
        }
        if properties.contains(.indicate) {
            score += 40
        }
        if properties.contains(.read) {
            score += 10
        }
        return score
    }

    static func supportsWrite(_ properties: CBCharacteristicProperties) -> Bool {
        return properties.contains(.write) || properties.contains(.writeWithoutResponse)
    }

    static func prefersWriteWithoutResponse(_ properties: CBCharacteristicProperties) -> Bool {
        return !properties.contains(.write) && properties.contains(.writeWithoutResponse)
    }

    static func formatProperties(_ properties: CBCharacteristicProperties) -> String {
        var flags: [String] = []
        if properties.contains(.write) {
            flags.append("W")
        }
        if properties.contains(.writeWithoutResponse) {
            flags.append("WNR")
        }
        if properties.contains(.notify) {
            flags.append("N")
        }
        if properties.contains(.indicate) {
            flags.append("I")
        }
        if properties.contains(.read) {
            flags.append("R")
        }
        return flags.isEmpty ? "-" : flags.joined(separator: "+")
    }

    static func formatWriteType(_ writeType: CBCharacteristicWriteType) -> String {
        return writeType == .withoutResponse ? "withoutResponse" : "withResponse"
    }
}

public class RapidKitPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, NTESVerifyCodeManagerDelegate {
    
    private static let TAG = "RapidKitPlugin"
    
    var flutterTextureRegistry: FlutterTextureRegistry!
    var centralManager: CBCentralManager?
    private var bluetoothStateResult: FlutterResult?
    private var bluetoothPermissionResult: FlutterResult?
    
    var textureEntryMap: [Int64: RapidTexture] = [:]
    
    private let locationManager = CLLocationManager()
    
    private var playerPtrToCapturedPicturePath = [Int64: String]()
    
    private var discoveredPeripherals = [CBPeripheral]()
    private var discoveredPeripheralsUUIDs = Set<String>()
    private var discoveredPeripheralNames = [String: String]()
    private var isDiscovering = false
    
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var writeType: CBCharacteristicWriteType = .withResponse
    private var preferredCharacteristics: [String]?
    private var writeCallback: FlutterResult?
    private var connectCallback: FlutterResult?
    private var pendingCharacteristicServiceUuids = Set<String>()
    private var characteristicCandidates = [RapidKitBleCharacteristicSelector.Candidate]()
    private var candidateCharacteristics = [CBCharacteristic]()
    
    private var pendingData: Data?
    private var currentPacketIndex: Int = 0
    private static let MTU_SIZE: Int = 20
    
    private static let CONNECT_TIMEOUT = 180.0
    private var connectTimer: Timer?
    private var retryCount = 0
    private var lastConnectedPeripheralId: String?
    
    private static let SERVICE_DISCOVERY_TIMEOUT = 10.0
    private var serviceDiscoveryTimer: Timer?
    
    private var verifyManager: NTESVerifyCodeManager?
    private var captchaResult: FlutterResult?
    private var voiceProcessingMediaChats = Set<Int>()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("RapidKitPlugin register ...")
        let channel = FlutterMethodChannel(name: METHOD_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        let instance = RapidKitPlugin()
        instance.flutterTextureRegistry = registrar.textures()
        registrar.addMethodCallDelegate(instance, channel: channel)        
        RAPID_Initialize();
        print("RapidKitPlugin register end.")
    }
    
    public override init() {
        super.init()
        print("RapidKitPlugin init ...")
        locationManager.delegate = self
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            
        case "requireLoggingCacheDirectory":
              requireLoggingCacheDirectory(result: result)
            
        case "requireWriteableCachePath":
            requireWriteableCachePath(result: result)
            
        case "localNetworkBroadcastAddress":
            let arguments = call.arguments as? [String: Any]
            localNetworkBroadcastAddress(result: result, logDetails: arguments?["logDetails"] as? Bool ?? true)
            
        case "isFileAccessPermissionGranted":
            isFileAccessPermissionGranted(result: result)
            
        case "requestFileAccessPermission":
            requestFileAccessPermission(result: result)

        case "exportCapturedPicture":
            exportCapturedPicture(call: call, result: result)
                        
        case "exportCapturedVideo":
            exportCapturedVideo(call: call, result: result)
            
        case "launchWiFiSettings":
            openWiFiSettings(result: result)
            
        case "requireLocationPermission":
            requestLocationPermission()
            result(nil)
            
        case "isLocationPermissionRequired":
            result(isLocationPermissionGranted())
            
        case "currentWifi":
            result(currentWifi())
            
        case "attachMediaChat":
            attachMediaChat(call: call, result: result)

        case "setIosVoiceProcessing":
            setIosVoiceProcessing(call: call, result: result)

        case "createAudioSession":
            createAudioSession(call: call, result: result)
            
        case "destroyAudioSession":
            destroyAudioSession(call: call, result: result)
        case "requireMicrophone":
            requireMicrophone(call: call, result: result)

        case "isMicrophoneRequired":
            isMicrophoneRequired(call: call, result: result)
            
        case "attachPlayerTexture":
            attachPlayerTexture(call: call, result: result)
            
        case "detachPlayerTexture":
            detachPlayerTexture(call: call, result: result)
            
        case "isBluetoothPermissionGranted":
            if #available(iOS 13.1, *) {
                let status = CBCentralManager.authorization
                result(status == .allowedAlways)
            } else if let manager = centralManager {
                result(manager.state != .unauthorized)
            } else {
                result(false)
            }
            
        case "acquireBluetoothPermission":
            bluetoothPermissionResult = result
            print("acquireBluetoothPermission centralManager: \(centralManager)")
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: self, queue: nil)
            } else {
                if #available(iOS 13.1, *) {
                    let status = CBCentralManager.authorization
                    result(status == .allowedAlways ? 1 : 2)
                } else {
                    result(centralManager!.state != .unauthorized ? 1 : 2)
                }
                bluetoothPermissionResult = nil
            }
            
        case "isBluetoothEnabled":
            bluetoothStateResult = result
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: self, queue: nil)
            } else if let manager = centralManager {
                result(manager.state == .poweredOn)
                bluetoothStateResult = nil
            }
            
        case "getBluetoothDevices":
            let devices = discoveredPeripherals.compactMap { peripheral -> [String: String]? in
                let uuid = peripheral.identifier.uuidString
                guard let name = resolvedPeripheralName(peripheral), !name.isEmpty else { return nil }
                return [
                    "name": name,
                    "address": uuid
                ]
            }
            result(devices)
            
        case "startBluetoothDiscovery":
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: self, queue: nil)
            }
            isDiscovering = true
            if let manager = centralManager, manager.state == .poweredOn {
                startDiscoveryInternal()
            }
            result(nil)
            
        case "stopBluetoothDiscovery":
            isDiscovering = false
            centralManager?.stopScan()
            result(nil)
            
        case "connectBluetoothDevice":
            guard let args = call.arguments as? [String: Any],
                  let mac = args["mac"] as? String else {
                print("Error: connectBluetoothDevice - Invalid arguments")
                result(false)
                return
            }
            
            let characteristics = args["characteristics"] as? [String]
            print("Debug: connectBluetoothDevice - Attempting to connect to device: \(mac)")
            print("Debug: connectBluetoothDevice - Preferred characteristics: \(String(describing: characteristics))")
            
            if let peripheral = connectedPeripheral,
               peripheral.identifier.uuidString == mac,
               writeCharacteristic != nil {
                print("Debug: connectBluetoothDevice - Already connected to device: \(mac)")
                result(true)
                return
            }
            
            connectCallback = result
            preferredCharacteristics = characteristics
            lastConnectedPeripheralId = mac
            retryCount = 0
            
            if let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == mac }) {
                print("Debug: connectBluetoothDevice - Found peripheral in discovered devices, attempting to connect")
                connectedPeripheral = peripheral
                peripheral.delegate = self
                startConnectTimer()
                centralManager?.connect(peripheral, options: nil)
            } else {
                print("Error: connectBluetoothDevice - Device not found in discovered peripherals")
                result(false)
            }
            
        case "writeBluetoothData":
            writeBluetoothData(call: call, result: result)
            
        case "disconnectBluetoothDevice":
            stopConnectTimer()
            if let peripheral = connectedPeripheral {
                print("Debug: disconnectBluetoothDevice - Disconnecting from: \(peripheral.identifier.uuidString)")
                centralManager?.cancelPeripheralConnection(peripheral)
            } else {
                print("Debug: disconnectBluetoothDevice - No connected peripheral to disconnect")
            }
            cleanupConnection()
            lastConnectedPeripheralId = nil
            result(nil)
            
        case "accountRobotCheck":
            handleAccountRobotCheck(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
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
    
    private func requireWriteableCachePath(result: @escaping FlutterResult) {
        let path = generateSandboxFilePath(subffix: "mp4") ?? ""
        result(path)
    }

    private func exportCapturedPicture(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let srcPath = args["cachePath"] as? String else {
            print("Error: Could not extract cachePath")
            result(false)
            return
        }

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: srcPath) {

            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            guard authorizationStatus == .authorized else {
                print("Error: Photo library access not authorized")
                result(false)
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let assetCreationRequest = PHAssetCreationRequest.forAsset()
                assetCreationRequest.addResource(with: .photo, fileURL: URL(fileURLWithPath: srcPath), options: nil)
            }) { success, error in
                if success {
                    print("Info: File successfully added to the photo library")
                    result(true)
                } else {
                    if let error = error {
                        print("Error: Failed to add file to the photo library - \(error.localizedDescription)")
                    } else {
                        print("Error: Failed to add file to the photo library for an unknown reason")
                    }
                    result(false)
                }
                                
                do {
                    try fileManager.removeItem(atPath: srcPath)
                    print("Info: Source file deleted successfully")
                } catch {
                    print("Error: Failed to delete source file - \(error.localizedDescription)")
                }
            }
        } else {
            print("Error: Source file does not exist")
            result(false)
        }
    }
    
    func isFileExistAndNotEmpty(atPath srcPath: String) -> UInt64 {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: srcPath) {
            do {
                let fileAttributes = try fileManager.attributesOfItem(atPath: srcPath)
                if let fileSize = fileAttributes[FileAttributeKey.size] as? UInt64 {
                    return fileSize
                }
            } catch {
                print("Error retrieving file attributes: \(error.localizedDescription)")
            }
        }
        
        return 0
    }
    
    private func exportCapturedVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let srcPath = args["cachePath"] as? String else {
            print("Error: Could not extract cachePath")
            result(false)
            return
        }
        
        let galleryName = args["galleryName"] as? String
        
        print("exportCapturedVideo: srcPath = \(srcPath)")
        let fileSize = isFileExistAndNotEmpty(atPath: srcPath)
        if (fileSize <= 0) {
            print("Error: Source path does not exist: \(srcPath)")
            result(false)
            return
        }
        
        print("exportCapturedVideo: Source path exists, fileSize = \(fileSize)")
        
        let fileManager = FileManager.default
        
        var finalSrcPath = srcPath
        var shouldCleanupTempFile = false
        
        if let galleryName = galleryName {
            let videoName = galleryName.hasSuffix(".mp4") ? galleryName : "\(galleryName).mp4"
            let tempDir = NSTemporaryDirectory()
            let newPath = (tempDir as NSString).appendingPathComponent(videoName)
            
            do {
                try fileManager.copyItem(atPath: srcPath, toPath: newPath)
                finalSrcPath = newPath
                shouldCleanupTempFile = true
            } catch {
                print("Warning: Failed to rename temp video file: \(error)")
            }
        }

            if fileManager.fileExists(atPath: finalSrcPath) {

                let authorizationStatus = PHPhotoLibrary.authorizationStatus()
                
                guard authorizationStatus == .authorized else {
                    print("Error: Photo library access not authorized")
                    result(false)
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    let assetCreationRequest = PHAssetCreationRequest.forAsset()
                    assetCreationRequest.addResource(with: .video, fileURL: URL(fileURLWithPath: finalSrcPath), options: nil)
                }) { success, error in
                    if success {
                        print("Info: Video file successfully added to the photo library")
                        result(true)
                    } else {
                        if let error = error {
                            print("Error: Failed to add video file to the photo library - \(error.localizedDescription)")
                        } else {
                            print("Error: Failed to add video file to the photo library for an unknown reason")
                        }
                        result(false)
                    }
                                    
                    do {
                        try fileManager.removeItem(atPath: srcPath)
                        if shouldCleanupTempFile && finalSrcPath != srcPath {
                            try? fileManager.removeItem(atPath: finalSrcPath)
                        }
                        print("Info: Source video file deleted successfully")
                    } catch {
                        print("Error: Failed to delete source video file - \(error.localizedDescription)")
                    }
                }
            } else {
                print("Error: Source video file does not exist")
                result(false)
            }
        
    }
    
    private func generateSandboxFilePath(subffix: String) -> String? {
        if let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileName = "rapid_captured_\(Int64(Date().timeIntervalSince1970 * 1_000_000)).\(subffix)"
            return cachesDirectory.appendingPathComponent(fileName).path
        }
        return nil
    }
    
    private func isFileAccessPermissionGranted(result: @escaping FlutterResult) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        result(authorizationStatus == .authorized )
    }
    
    private func requestFileAccessPermission(result: @escaping FlutterResult) {
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Info: Photo library access granted")
                result(1)
            case .denied:
                print("Error: Photo library access denied")
                result(2)
            case .restricted:
                print("Error: Photo library access restricted")
                result(2)
            case .notDetermined:
                print("Error: Photo library access not determined")
                result(2)
            @unknown default:
                print("Error: Unknown photo library access status")
                result(2)
            }
        }
    }
    
    private func localNetworkBroadcastAddress(result: @escaping FlutterResult, logDetails: Bool = true) {
        if let broadcastAddress = getBroadcastAddress(logDetails: logDetails) {
            result(broadcastAddress)
        } else {
            result("0.0.0.0")
        }
    }
    
    private func logInterfaceDetails(_ interface: ifaddrs, name: String, index: Int, logDetails: Bool = true) {
        guard logDetails else { return }
        guard let address = interface.ifa_addr else {
            Logging.i(RapidKitPlugin.TAG, "[getBroadcastAddress] interface[\(index)]: \(name) | No address")
            return
        }
        let family = address.pointee.sa_family
        var familyName = ""
        var ipAddress = ""
        var netmask = ""
        var flags = ""
        
        switch family {
        case UInt8(AF_INET):
            familyName = "IPv4"
            let addr = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0 }
            if let ipPtr = inet_ntoa(addr.pointee.sin_addr) {
                ipAddress = String(cString: ipPtr)
            }
            if let netmaskPtr = interface.ifa_netmask?.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { $0 }) {
                if let maskPtr = inet_ntoa(netmaskPtr.pointee.sin_addr) {
                    netmask = String(cString: maskPtr)
                }
            }
        case UInt8(AF_INET6):
            familyName = "IPv6"
        case UInt8(AF_LINK):
            familyName = "Link"
        default:
            familyName = "Other(\(family))"
        }
        
        let interfaceFlags = interface.ifa_flags
        var flagsArray: [String] = []
        if (interfaceFlags & UInt32(IFF_UP)) != 0 { flagsArray.append("UP") }
        if (interfaceFlags & UInt32(IFF_BROADCAST)) != 0 { flagsArray.append("BROADCAST") }
        if (interfaceFlags & UInt32(IFF_LOOPBACK)) != 0 { flagsArray.append("LOOPBACK") }
        if (interfaceFlags & UInt32(IFF_RUNNING)) != 0 { flagsArray.append("RUNNING") }
        flags = flagsArray.joined(separator: "|")
        
        Logging.i(RapidKitPlugin.TAG, "[getBroadcastAddress] interface[\(index)]: \(name) | \(familyName) | IP: \(ipAddress.isEmpty ? "N/A" : ipAddress) | Mask: \(netmask.isEmpty ? "N/A" : netmask) | Flags: \(flags)")
    }
    
    private func calculateBroadcastAddress(from interface: ifaddrs, name: String, logDetails: Bool = true) -> String? {
        guard let address = interface.ifa_addr else { return nil }
        guard address.pointee.sa_family == UInt8(AF_INET) else { return nil }
        guard let netmask = interface.ifa_netmask else { return nil }
        
        let addr = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0 }
        let mask = netmask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0 }
        
        guard let ipPtr = inet_ntoa(addr.pointee.sin_addr) else {
            logBroadcastAddress("[getBroadcastAddress] failed to convert \(name) IP to string", logDetails: logDetails)
            return nil
        }
        let ipString = String(cString: ipPtr)
        guard let maskPtr = inet_ntoa(mask.pointee.sin_addr) else {
            logBroadcastAddress("[getBroadcastAddress] failed to convert \(name) IP or netmask to string", logDetails: logDetails)
            return nil
        }
        let maskString = String(cString: maskPtr)
        logBroadcastAddress("[getBroadcastAddress] \(name) IP: \(ipString), netmask: \(maskString)", logDetails: logDetails)
        
        guard ipString != "0.0.0.0" && maskString != "0.0.0.0" else {
            logBroadcastAddress("[getBroadcastAddress] \(name) has invalid IP or netmask", logDetails: logDetails)
            return nil
        }
        
        let broadcast = (addr.pointee.sin_addr.s_addr | ~mask.pointee.sin_addr.s_addr).littleEndian
        
        var bcastAddr = in_addr(s_addr: broadcast)
        var bcastStr = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let conversionResult = inet_ntop(AF_INET, &bcastAddr, &bcastStr, socklen_t(INET_ADDRSTRLEN))
        
        if conversionResult != nil && bcastStr[0] != 0 {
            let broadcastAddress = String(cString: bcastStr)
            logBroadcastAddress("[getBroadcastAddress] successfully calculated \(name) broadcast address: \(broadcastAddress)", logDetails: logDetails)
            return broadcastAddress
        } else {
            logBroadcastAddress("[getBroadcastAddress] failed to convert \(name) broadcast address to string", logDetails: logDetails)
            return nil
        }
    }
    
    private func logBroadcastAddress(_ message: @autoclosure () -> String, logDetails: Bool) {
        if logDetails { Logging.i(RapidKitPlugin.TAG, message()) }
    }

    func getBroadcastAddress(logDetails: Bool = true) -> String? {
        logBroadcastAddress("[getBroadcastAddress] starting broadcast address discovery", logDetails: logDetails)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var broadcastAddress: String?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            logBroadcastAddress("[getBroadcastAddress] failed to retrieve network interfaces, getifaddrs returned error", logDetails: logDetails)
            return nil
        }
        
        logBroadcastAddress("[getBroadcastAddress] successfully retrieved network interfaces", logDetails: logDetails)
        var interfaceCount = 0
        var ipv4Interfaces: [(String, ifaddrs)] = []
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let interfaceName = String(cString: interface.ifa_name)
            interfaceCount += 1
            
            logInterfaceDetails(interface, name: interfaceName, index: interfaceCount, logDetails: logDetails)
            
            guard let address = interface.ifa_addr else { continue }
            if address.pointee.sa_family == UInt8(AF_INET) {
                let flags = interface.ifa_flags
                if (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_LOOPBACK)) == 0 {
                    ipv4Interfaces.append((interfaceName, interface))
                    logBroadcastAddress("[getBroadcastAddress] found valid IPv4 interface: \(interfaceName)", logDetails: logDetails)
                }
            }
        }
        
        logBroadcastAddress("[getBroadcastAddress] scanned \(interfaceCount) total interfaces, found \(ipv4Interfaces.count) valid IPv4 interfaces", logDetails: logDetails)
        
        let preferredOrder = ["en0", "en1", "en2", "en3", "en4", "en5"]
        
        for preferredName in preferredOrder {
            if let interfaceData = ipv4Interfaces.first(where: { $0.0 == preferredName }) {
                logBroadcastAddress("[getBroadcastAddress] trying preferred interface: \(preferredName)", logDetails: logDetails)
                if let result = calculateBroadcastAddress(from: interfaceData.1, name: preferredName, logDetails: logDetails) {
                    broadcastAddress = result
                    break
                }
            }
        }
        
        if broadcastAddress == nil {
            logBroadcastAddress("[getBroadcastAddress] no preferred interface found, trying any valid interface", logDetails: logDetails)
            for (name, interface) in ipv4Interfaces {
                if !preferredOrder.contains(name) {
                    logBroadcastAddress("[getBroadcastAddress] trying fallback interface: \(name)", logDetails: logDetails)
                    if let result = calculateBroadcastAddress(from: interface, name: name, logDetails: logDetails) {
                        broadcastAddress = result
                        break
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        
        if let result = broadcastAddress {
            logBroadcastAddress("[getBroadcastAddress] broadcast address discovery completed successfully: \(result)", logDetails: logDetails)
        } else {
            logBroadcastAddress("[getBroadcastAddress] broadcast address discovery failed, no valid interface found", logDetails: logDetails)
        }
        
        return broadcastAddress
    }
    
    private func currentWifi() -> String {
        var wifiName = ""
                let wifiInterfaces = CNCopySupportedInterfaces()
                guard wifiInterfaces != nil else {
                    return wifiName
                }

                let interfaceArr = CFBridgingRetain(wifiInterfaces) as! [String]
                if interfaceArr.count > 0 {
                    let interfaceName = interfaceArr[0] as CFString
                    let ussafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName)

                    if ussafeInterfaceData != nil {
                        let interfaceData = ussafeInterfaceData as! [String: Any]
                        wifiName = interfaceData["SSID"]! as! String
                    }
                }
                return wifiName
    }
    
    private func isLocationPermissionGranted() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    private func openWiFiSettings(result: @escaping FlutterResult) {
        if let url = URL(string: "App-Prefs:root=WIFI") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        result(nil)
      }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func attachMediaChat(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let chatPtr = args["mediaChatPtr"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Could not extract mediaChatPtr", details: nil))
            return
        }

        let mediaChatPtr: uintptr_t = uintptr_t(chatPtr)

        let voiceProcessing = args["iosVoiceProcessing"] as? Bool ?? false
        if voiceProcessing {
            guard let playerPtr = args["playbackPlayerPtr"] as? Int else {
                result(FlutterError(
                    code: "INVALID_ARGUMENT",
                    message: "VoiceProcessingIO requires playbackPlayerPtr",
                    details: nil
                ))
                return
            }
            result(RAPID_IOS_VoiceProcessingIO_Binding(uintptr_t(playerPtr), mediaChatPtr) == RAPID_TRUE)
            return
        }

        if let playerPtr = args["playbackPlayerPtr"] as? Int {
            result(RAPID_IOS_DefaultAudioIO_Binding(uintptr_t(playerPtr), mediaChatPtr) == RAPID_TRUE)
            return
        }

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

    private func setIosVoiceProcessing(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let chatPtr = args["mediaChatPtr"] as? Int,
              let enable = args["enable"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Could not extract iOS VoiceProcessingIO arguments", details: nil))
            return
        }

        result(enable ? enableVoiceProcessing(chatPtr: chatPtr) : disableVoiceProcessing(chatPtr: chatPtr))
    }

    private func enableVoiceProcessing(chatPtr: Int) -> Bool {
        if voiceProcessingMediaChats.contains(chatPtr) { return true }

        let firstRetain = voiceProcessingMediaChats.isEmpty
        if firstRetain {
            AudioSessionManager.shared.retainSession()
            guard AudioSessionManager.shared.retainVoiceProcessing() else {
                AudioSessionManager.shared.releaseSession()
                Logging.e(Self.TAG, "[setIosVoiceProcessing] enable failed")
                return false
            }
        }

        voiceProcessingMediaChats.insert(chatPtr)
        Logging.i(
            Self.TAG,
            "[setIosVoiceProcessing] requested=true actual=true ref_count=\(voiceProcessingMediaChats.count)"
        )
        return true
    }

    private func disableVoiceProcessing(chatPtr: Int) -> Bool {
        guard voiceProcessingMediaChats.remove(chatPtr) != nil else { return true }
        guard voiceProcessingMediaChats.isEmpty else {
            Logging.i(
                Self.TAG,
                "[setIosVoiceProcessing] requested=false actual=true ref_count=\(voiceProcessingMediaChats.count)"
            )
            return true
        }

        AudioSessionManager.shared.releaseVoiceProcessing()
        AudioSessionManager.shared.releaseSession()
        Logging.i(Self.TAG, "[setIosVoiceProcessing] requested=false actual=false ref_count=0")
        return true
    }

    private func createAudioSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        AudioSessionManager.shared.retainSession()
        result(nil)
    }
    
    private func destroyAudioSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        AudioSessionManager.shared.releaseSession()
        result(nil)
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
                print("Error: Failed to bind callback, result: \(bindingResult)")
            }
        }
        
        if textureId < 0 {
            fatalError("[Rapid-Bridging][iOS] Failed registering texture to Flutter registry")
        }

        
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
    
    private func writeNextPacket() {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let pendingData = pendingData else {
            print("[BLE] Write aborted: Missing peripheral, characteristic, or data")
            return
        }
        
        let startIndex = currentPacketIndex * RapidKitPlugin.MTU_SIZE
        guard startIndex < pendingData.count else {
            print("[BLE] Write completed: All packets sent")
            self.pendingData = nil
            self.currentPacketIndex = 0
            writeCallback?(true)
            writeCallback = nil
            return
        }
        
        let endIndex = min(startIndex + RapidKitPlugin.MTU_SIZE, pendingData.count)
        let packet = pendingData.subdata(in: startIndex..<endIndex)
        
        let currentWriteType = writeType
        print("[BLE] Writing packet \(currentPacketIndex + 1) size: \(packet.count), type: \(RapidKitBleCharacteristicSelector.formatWriteType(currentWriteType))")
        peripheral.writeValue(packet, for: characteristic, type: currentWriteType)

        if currentWriteType == .withoutResponse {
            currentPacketIndex += 1
            if peripheral.canSendWriteWithoutResponse {
                DispatchQueue.main.async { [weak self] in
                    self?.writeNextPacket()
                }
            }
        }
    }
    
    private func writeBluetoothData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let data = call.arguments as? FlutterStandardTypedData else {
            print("[BLE] Write error: Invalid data format")
            result(false)
            return
        }
        
        guard let characteristic = writeCharacteristic, let peripheral = connectedPeripheral else {
            print("[BLE] Write error: No connection available")
            result(false)
            return
        }
        
        print("[BLE] Write started - Length: \(data.data.count), Characteristic: \(characteristic.uuid.uuidString), Device: \(peripheral.identifier.uuidString)")
        
        pendingData = data.data
        currentPacketIndex = 0
        writeCallback = result
        writeNextPacket()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if writeType == .withoutResponse {
            return
        }

        if let error = error {
            print("[BLE] Write failed: \(error.localizedDescription)")
            pendingData = nil
            currentPacketIndex = 0
            writeCallback?(false)
            writeCallback = nil
        } else {
            print("[BLE] Packet \(currentPacketIndex + 1) written successfully")
            currentPacketIndex += 1
            writeNextPacket()
        }
    }

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        writeNextPacket()
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier.uuidString
        let localName = normalizedPeripheralName(advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        let peripheralName = normalizedPeripheralName(peripheral.name)
        if let name = preferredPeripheralName(current: discoveredPeripheralNames[uuid], localName: localName, peripheralName: peripheralName) {
            discoveredPeripheralNames[uuid] = name
        }
        print("[BLE] Discovered device - UUID: \(uuid), Name: \(peripheralName ?? "Unknown"), LocalName: \(localName ?? "Unknown"), RSSI: \(RSSI)")
        
        if !discoveredPeripheralsUUIDs.contains(uuid) {
            discoveredPeripheralsUUIDs.insert(uuid)
            discoveredPeripherals.append(peripheral)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        print("[BLE] State changed: \(state.rawValue)")
        
        if let permissionResult = bluetoothPermissionResult {
            switch state {
            case .unauthorized:
                permissionResult(2)
            case .poweredOn, .poweredOff, .resetting:
                permissionResult(1)
            default:
                permissionResult(2)
            }
            bluetoothPermissionResult = nil
        }
        
        if let stateResult = bluetoothStateResult {
            stateResult(state == .poweredOn)
            bluetoothStateResult = nil
        }
        
        if state == .poweredOn && isDiscovering {
            startDiscoveryInternal()
        } else if state != .poweredOn {
            centralManager?.stopScan()
        }
    }
    
    private func startDiscoveryInternal() {
        print("[BLE] Starting device discovery")
        discoveredPeripherals.removeAll()
        discoveredPeripheralsUUIDs.removeAll()
        discoveredPeripheralNames.removeAll()
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        centralManager?.scanForPeripherals(withServices: nil, options: options)
    }

    private func normalizedPeripheralName(_ name: String?) -> String? {
        guard let value = name?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }

    private func resolvedPeripheralName(_ peripheral: CBPeripheral) -> String? {
        let uuid = peripheral.identifier.uuidString
        return discoveredPeripheralNames[uuid] ?? normalizedPeripheralName(peripheral.name)
    }

    private func preferredPeripheralName(current: String?, localName: String?, peripheralName: String?) -> String? {
        let candidate = localName ?? peripheralName
        guard let name = candidate else { return current }
        guard let current = current else { return name }
        if current.hasPrefix("AICAM_") && !name.hasPrefix("AICAM_") {
            return current
        }
        if !current.hasPrefix("AICAM_") && name.hasPrefix("AICAM_") {
            return name
        }
        return localName != nil ? name : current
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        stopServiceDiscoveryTimer()
        
        if let error = error {
            print("[BLE] Service discovery failed: \(error.localizedDescription), State: \(peripheral.state.rawValue)")
            retryConnection()
            return
        }
        
        print("[BLE] Services discovered - Count: \(peripheral.services?.count ?? 0), State: \(peripheral.state.rawValue)")
        
        guard let services = peripheral.services, !services.isEmpty else {
            print("[BLE] No services found")
            retryConnection()
            return
        }

        pendingCharacteristicServiceUuids = Set(services.map { $0.uuid.uuidString.lowercased() })
        characteristicCandidates.removeAll()
        candidateCharacteristics.removeAll()
        
        for service in services {
            print("[BLE] Service found - UUID: \(service.uuid.uuidString), Primary: \(service.isPrimary)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("[BLE] Characteristic discovery failed: \(error.localizedDescription)")
            retryConnection()
            return
        }
        
        print("[BLE] Characteristics discovered - Service: \(service.uuid.uuidString)")
        
        if let characteristics = service.characteristics, !characteristics.isEmpty {
            for characteristic in characteristics {
                let uuid = characteristic.uuid.uuidString
                let properties = characteristic.properties
                let score = RapidKitBleCharacteristicSelector.calculateScore(properties)
                let flags = RapidKitBleCharacteristicSelector.formatProperties(properties)

                print("[BLE] Characteristic - UUID: \(uuid), Properties: \(properties.rawValue), Flags: \(flags), Score: \(score)")

                characteristicCandidates.append(
                    RapidKitBleCharacteristicSelector.Candidate(
                        uuid: uuid,
                        properties: properties,
                        serviceUuid: service.uuid.uuidString,
                        index: candidateCharacteristics.count
                    )
                )
                candidateCharacteristics.append(characteristic)
            }
        } else {
            print("[BLE] No characteristics found")
        }

        pendingCharacteristicServiceUuids.remove(service.uuid.uuidString.lowercased())
        finishCharacteristicDiscoveryIfNeeded()
    }

    private func finishCharacteristicDiscoveryIfNeeded() {
        guard pendingCharacteristicServiceUuids.isEmpty else {
            return
        }

        guard let selection = RapidKitBleCharacteristicSelector.select(
            candidates: characteristicCandidates,
            preferredUuids: preferredCharacteristics
        ), candidateCharacteristics.indices.contains(selection.candidate.index) else {
            print("[BLE] No writable characteristic found")
            retryConnection()
            return
        }

        let selectedCharacteristic = candidateCharacteristics[selection.candidate.index]
        writeType = RapidKitBleCharacteristicSelector.prefersWriteWithoutResponse(selection.candidate.properties) ? .withoutResponse : .withResponse
        writeCharacteristic = selectedCharacteristic
        print(
            "[BLE] Selected \(selection.reason.rawValue) characteristic: " +
            "uuid=\(selection.candidate.uuid), service=\(selection.candidate.serviceUuid), " +
            "flags=\(RapidKitBleCharacteristicSelector.formatProperties(selection.candidate.properties)), " +
            "score=\(selection.score), writeType=\(RapidKitBleCharacteristicSelector.formatWriteType(writeType))"
        )
        connectCallback?(true)
        writeCallback = nil
        connectCallback = nil
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[BLE] Connected - Device: \(peripheral.identifier.uuidString), Name: \(peripheral.name ?? "Unknown"), State: \(peripheral.state.rawValue)")
        
        stopConnectTimer()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        if peripheral.delegate == nil {
            print("[BLE] Failed to set delegate")
            connectCallback?(false)
            return
        }
        
        print("[BLE] Starting service discovery (Timeout: \(RapidKitPlugin.SERVICE_DISCOVERY_TIMEOUT)s)")
        startServiceDiscoveryTimer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("[BLE] Initiating service discovery")
            peripheral.discoverServices(nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[BLE] Disconnected - Device: \(peripheral.identifier.uuidString), Error: \(error?.localizedDescription ?? "None")")
        stopServiceDiscoveryTimer()
        
        if let _ = error {
            retryConnection()
        } else {
            cleanupConnection()
            lastConnectedPeripheralId = nil
            connectCallback?(false)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[BLE] Connection failed - Device: \(peripheral.identifier.uuidString), Error: \(error?.localizedDescription ?? "Unknown")")
        retryConnection()
    }
    
    private func startConnectTimer() {
        stopConnectTimer()
        connectTimer = Timer.scheduledTimer(withTimeInterval: RapidKitPlugin.CONNECT_TIMEOUT, repeats: false) { [weak self] _ in
            print("[BLE] Connection timeout")
            self?.handleConnectTimeout()
        }
    }
    
    private func stopConnectTimer() {
        connectTimer?.invalidate()
        connectTimer = nil
    }
    
    private func handleConnectTimeout() {
        print("[BLE] Connection timeout occurred")
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectCallback?(false)

        writeCallback = nil
        connectCallback = nil

        cleanupConnection()    
    }
    
    private func startServiceDiscoveryTimer() {
        stopServiceDiscoveryTimer()
        serviceDiscoveryTimer = Timer.scheduledTimer(withTimeInterval: RapidKitPlugin.SERVICE_DISCOVERY_TIMEOUT, repeats: false) { [weak self] _ in
            print("[BLE] Service discovery timeout")
            self?.handleServiceDiscoveryTimeout()
        }
    }
    
    private func stopServiceDiscoveryTimer() {
        serviceDiscoveryTimer?.invalidate()
        serviceDiscoveryTimer = nil
    }
    
    private func handleServiceDiscoveryTimeout() {
        print("[BLE] Service discovery timeout occurred")
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        cleanupConnection()
        retryConnection()
    }
    
    private func cleanupConnection() {
        print("[BLE] Cleaning up connection")
        stopConnectTimer()
        stopServiceDiscoveryTimer()
        connectedPeripheral = nil
        writeCharacteristic = nil
        writeType = .withResponse
        preferredCharacteristics = nil
        writeCallback = nil
        connectCallback = nil
        pendingData = nil
        currentPacketIndex = 0
        pendingCharacteristicServiceUuids.removeAll()
        characteristicCandidates.removeAll()
        candidateCharacteristics.removeAll()
    }
    
    private func retryConnection() {
        guard let peripheralId = lastConnectedPeripheralId,
              let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == peripheralId }) else {
            print("[BLE] Retry failed - Device not found")
            cleanupConnection()
            lastConnectedPeripheralId = nil
            return
        }
        
        print("[BLE] Retrying connection")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        startConnectTimer()
        centralManager?.connect(peripheral, options: nil)
    }
    
    private func handleAccountRobotCheck(result: @escaping FlutterResult) {
        captchaResult = result
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        verifyManager = NTESVerifyCodeManager.getInstance()
        verifyManager?.delegate = self        
        verifyManager?.alpha = 0.5
        verifyManager?.color = UIColor.lightGray.withAlphaComponent(0.5) 
        verifyManager?.configureVerifyCode("f9c76200db674493a1319a4a3b6cb99e", timeout: 10000)        
        verifyManager?.openVerifyCodeView(nil)
    }    
    
    public func verifyCodeValidateFinish(_ result: Bool, validate: String?, message: String?) {
        print("[verifyCodeValidateFinish] result: \(result), validate: \(validate ?? "nil"), message: \(message ?? "nil")")
        if result {
            captchaResult?(validate ?? "")
        } else {
            captchaResult?("ERROR:UNKNOWN")
        }
        captchaResult = nil
    }
    
    public func verifyCodeInitFailed(_ error: [Any]?) {
        print("[verifyCodeInitFailed] error: \(error?.description ?? "nil")")
        captchaResult?("ERROR:INIT_FAILED")
        captchaResult = nil
    }
    
    public func verifyCodeCloseWindow(_ close: Int) {
        print("[verifyCodeCloseWindow] close: \(close)")
        if let result = captchaResult {
            result("ERROR:CLOSED")
            captchaResult = nil
        }
    }
}
