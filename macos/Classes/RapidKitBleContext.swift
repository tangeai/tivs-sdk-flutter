import CoreBluetooth
import Foundation

private struct RapidKitBleCharacteristicSelector {
    private static let bluetoothBaseUuidSuffix = "-0000-1000-8000-00805f9b34fb"
    private static let sigAssignedServiceUuidRanges = [
        0x1800...0x180a,
        0x180d...0x1816,
        0x1818...0x1829,
        0x183a...0x1840,
        0x1843...0x1860
    ]

    struct Candidate {
        let characteristic: CBCharacteristic
        let uuid: String
        let serviceUuid: String
        let score: Int
    }

    static func select(_ candidates: [Candidate], preferredUuids: [String]?) -> Candidate? {
        let preferred = Set((preferredUuids ?? []).map(normalizeUuid))
        var preferredCandidate: Candidate?
        var automaticCandidate: Candidate?

        for candidate in candidates where candidate.score > 0 {
            if preferred.contains(normalizeUuid(candidate.uuid)),
               candidate.score > (preferredCandidate?.score ?? -1) {
                preferredCandidate = candidate
            }
            if !isSigAssignedServiceUuid(candidate.serviceUuid),
               candidate.score > (automaticCandidate?.score ?? -1) {
                automaticCandidate = candidate
            }
        }
        return preferredCandidate ?? automaticCandidate
    }

    static func score(_ properties: CBCharacteristicProperties) -> Int {
        guard properties.contains(.write) || properties.contains(.writeWithoutResponse) else {
            return 0
        }
        var score = 100
        if properties.contains(.notify) { score += 50 }
        if properties.contains(.indicate) { score += 40 }
        if properties.contains(.read) { score += 10 }
        return score
    }

    static func writeType(_ properties: CBCharacteristicProperties) -> CBCharacteristicWriteType {
        return !properties.contains(.write) && properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
    }

    private static func normalizeUuid(_ uuid: String) -> String {
        let normalized = uuid.lowercased()
        if normalized.count == 4 { return "0000\(normalized)\(bluetoothBaseUuidSuffix)" }
        if normalized.count == 8 { return "\(normalized)\(bluetoothBaseUuidSuffix)" }
        return normalized
    }

    private static func isSigAssignedServiceUuid(_ uuid: String) -> Bool {
        let normalized = normalizeUuid(uuid)
        guard normalized.count == 36,
              normalized.hasPrefix("0000"),
              normalized.hasSuffix(bluetoothBaseUuidSuffix),
              let shortUuid = Int(normalized.dropFirst(4).prefix(4), radix: 16) else {
            return false
        }
        return sigAssignedServiceUuidRanges.contains { $0.contains(shortUuid) }
    }
}

final class RapidKitBleContext: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private static let permissionGrantedResult = 1
    private static let permissionDeniedResult = 2
    private static let connectTimeout: TimeInterval = 30
    private static let serviceDiscoveryTimeout: TimeInterval = 10
    private static let writeTimeout: TimeInterval = 10
    private static let packetLength = 20

    private var centralManager: CBCentralManager?
    private var permissionCompletion: ((Int) -> Void)?
    private var enabledCompletion: ((Bool) -> Void)?

    private var isDiscovering = false
    private var discoveredPeripherals = [CBPeripheral]()
    private var discoveredPeripheralIds = Set<String>()
    private var discoveredPeripheralNames = [String: String]()

    private var connectedPeripheral: CBPeripheral?
    private var preferredCharacteristics: [String]?
    private var writeCharacteristic: CBCharacteristic?
    private var writeType: CBCharacteristicWriteType = .withResponse
    private var characteristicCandidates = [RapidKitBleCharacteristicSelector.Candidate]()
    private var pendingServices = Set<ObjectIdentifier>()
    private var connectCompletion: ((Bool) -> Void)?
    private var connectTimer: Timer?
    private var serviceDiscoveryTimer: Timer?

    private var pendingData: Data?
    private var currentPacketIndex = 0
    private var writeCompletion: ((Bool) -> Void)?
    private var writeTimer: Timer?

    func permissionGranted() -> Bool {
        if #available(macOS 10.15, *) {
            return CBCentralManager.authorization == .allowedAlways
        }
        guard let manager = centralManager else { return false }
        return manager.state != .unauthorized
    }

    func acquirePermission(completion: @escaping (Int) -> Void) {
        if #available(macOS 10.15, *) {
            switch CBCentralManager.authorization {
            case .allowedAlways:
                completion(RapidKitBleContext.permissionGrantedResult)
                return
            case .denied, .restricted:
                completion(RapidKitBleContext.permissionDeniedResult)
                return
            case .notDetermined:
                break
            @unknown default:
                completion(RapidKitBleContext.permissionDeniedResult)
                return
            }
        }
        guard permissionCompletion == nil else {
            completion(RapidKitBleContext.permissionDeniedResult)
            return
        }
        permissionCompletion = completion
        _ = requireCentralManager()
        resolvePermissionIfPossible()
    }

    func checkEnabled(completion: @escaping (Bool) -> Void) {
        guard enabledCompletion == nil else {
            completion(false)
            return
        }
        let manager = requireCentralManager()
        if manager.state == .unknown || manager.state == .resetting {
            enabledCompletion = completion
        } else {
            completion(manager.state == .poweredOn)
        }
    }

    func startDiscovery() {
        isDiscovering = true
        let manager = requireCentralManager()
        if manager.state == .poweredOn { startDiscoveryInternal() }
    }

    func stopDiscovery() {
        isDiscovering = false
        centralManager?.stopScan()
    }

    func getNearbyDevices() -> [[String: String]] {
        return discoveredPeripherals.compactMap { peripheral in
            let identifier = peripheral.identifier.uuidString
            guard let name = resolvedPeripheralName(peripheral), !name.isEmpty else { return nil }
            return ["name": name, "address": identifier]
        }
    }

    func connect(identifier: String,
                 preferredCharacteristics: [String]?,
                 completion: @escaping (Bool) -> Void) {
        guard connectCompletion == nil else {
            completion(false)
            return
        }

        let manager = requireCentralManager()
        guard manager.state == .poweredOn else {
            completion(false)
            return
        }
        if let peripheral = connectedPeripheral,
           identifiersMatch(peripheral.identifier.uuidString, identifier),
           peripheral.state == .connected,
           writeCharacteristic != nil {
            completion(true)
            return
        }
        guard let peripheral = discoveredPeripherals.first(where: {
            identifiersMatch($0.identifier.uuidString, identifier)
        }) else {
            NSLog("[RapidKitBleContext][connect] device not found, identifier=%@", identifier)
            completion(false)
            return
        }

        if let current = connectedPeripheral, current.identifier != peripheral.identifier {
            manager.cancelPeripheralConnection(current)
            clearConnectionState()
        }
        self.preferredCharacteristics = preferredCharacteristics
        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectCompletion = completion
        startConnectTimer()
        manager.connect(peripheral, options: nil)
    }

    func disconnect(identifier: String) {
        guard let peripheral = connectedPeripheral else { return }
        if !identifier.isEmpty && !identifiersMatch(peripheral.identifier.uuidString, identifier) {
            return
        }

        let pendingConnect = connectCompletion
        connectCompletion = nil
        let pendingWrite = writeCompletion
        writeCompletion = nil
        clearConnectionState()
        centralManager?.cancelPeripheralConnection(peripheral)
        pendingConnect?(false)
        pendingWrite?(false)
    }

    func write(data: Data, completion: @escaping (Bool) -> Void) {
        guard !data.isEmpty,
              writeCompletion == nil,
              let peripheral = connectedPeripheral,
              peripheral.state == .connected,
              writeCharacteristic != nil else {
            completion(false)
            return
        }

        pendingData = data
        currentPacketIndex = 0
        writeCompletion = completion
        startWriteTimer()
        writeNextPacket()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        resolvePermissionIfPossible()
        if let completion = enabledCompletion,
           central.state != .unknown,
           central.state != .resetting {
            enabledCompletion = nil
            completion(central.state == .poweredOn)
        }

        if central.state == .poweredOn {
            if isDiscovering { startDiscoveryInternal() }
            return
        }

        central.stopScan()
        if connectCompletion != nil || connectedPeripheral != nil {
            failConnection("Bluetooth unavailable")
        } else if writeCompletion != nil {
            completeWrite(false)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let identifier = peripheral.identifier.uuidString
        let localName = normalizedName(advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        let peripheralName = normalizedName(peripheral.name)
        if let name = preferredName(current: discoveredPeripheralNames[identifier],
                                    localName: localName,
                                    peripheralName: peripheralName) {
            discoveredPeripheralNames[identifier] = name
        }
        if discoveredPeripheralIds.insert(identifier).inserted {
            discoveredPeripherals.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        stopConnectTimer()
        peripheral.delegate = self
        startServiceDiscoveryTimer()
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        failConnection(error?.localizedDescription ?? "Connection failed")
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        let pendingConnect = connectCompletion
        connectCompletion = nil
        let pendingWrite = writeCompletion
        writeCompletion = nil
        clearConnectionState()
        pendingConnect?(false)
        pendingWrite?(false)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        if let error = error {
            failConnection(error.localizedDescription)
            return
        }
        guard let services = peripheral.services, !services.isEmpty else {
            failConnection("No GATT services")
            return
        }

        characteristicCandidates.removeAll()
        pendingServices = Set(services.map { ObjectIdentifier($0) })
        for service in services { peripheral.discoverCharacteristics(nil, for: service) }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        if let error = error {
            failConnection(error.localizedDescription)
            return
        }

        for characteristic in service.characteristics ?? [] {
            characteristicCandidates.append(
                RapidKitBleCharacteristicSelector.Candidate(
                    characteristic: characteristic,
                    uuid: characteristic.uuid.uuidString,
                    serviceUuid: service.uuid.uuidString,
                    score: RapidKitBleCharacteristicSelector.score(characteristic.properties)
                )
            )
        }
        pendingServices.remove(ObjectIdentifier(service))
        finishCharacteristicDiscoveryIfPossible()
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let expectedCharacteristic = writeCharacteristic else { return }
        guard peripheral.identifier == connectedPeripheral?.identifier,
              characteristic === expectedCharacteristic,
              writeType == .withResponse else { return }
        if error != nil {
            completeWrite(false)
            return
        }
        currentPacketIndex += 1
        writeNextPacket()
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        guard peripheral.identifier == connectedPeripheral?.identifier,
              writeType == .withoutResponse else { return }
        writeNextPacket()
    }

    private func requireCentralManager() -> CBCentralManager {
        if let manager = centralManager { return manager }
        let manager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        centralManager = manager
        return manager
    }

    private func resolvePermissionIfPossible() {
        guard let completion = permissionCompletion else { return }
        if #available(macOS 10.15, *) {
            switch CBCentralManager.authorization {
            case .allowedAlways:
                permissionCompletion = nil
                completion(RapidKitBleContext.permissionGrantedResult)
            case .denied, .restricted:
                permissionCompletion = nil
                completion(RapidKitBleContext.permissionDeniedResult)
            case .notDetermined:
                break
            @unknown default:
                permissionCompletion = nil
                completion(RapidKitBleContext.permissionDeniedResult)
            }
            return
        }
        guard let manager = centralManager, manager.state != .unknown else { return }
        permissionCompletion = nil
        completion(manager.state == .unauthorized
            ? RapidKitBleContext.permissionDeniedResult
            : RapidKitBleContext.permissionGrantedResult)
    }

    private func startDiscoveryInternal() {
        guard let manager = centralManager, manager.state == .poweredOn else { return }
        discoveredPeripherals.removeAll()
        discoveredPeripheralIds.removeAll()
        discoveredPeripheralNames.removeAll()
        manager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    private func normalizedName(_ name: String?) -> String? {
        guard let value = name?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private func preferredName(current: String?,
                               localName: String?,
                               peripheralName: String?) -> String? {
        let candidate = localName ?? peripheralName
        guard let name = candidate else { return current }
        guard let current = current else { return name }
        if current.hasPrefix("AICAM_") && !name.hasPrefix("AICAM_") { return current }
        if !current.hasPrefix("AICAM_") && name.hasPrefix("AICAM_") { return name }
        return localName != nil ? name : current
    }

    private func resolvedPeripheralName(_ peripheral: CBPeripheral) -> String? {
        return discoveredPeripheralNames[peripheral.identifier.uuidString]
            ?? normalizedName(peripheral.name)
    }

    private func identifiersMatch(_ lhs: String, _ rhs: String) -> Bool {
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }

    private func finishCharacteristicDiscoveryIfPossible() {
        guard pendingServices.isEmpty else { return }
        guard let selected = RapidKitBleCharacteristicSelector.select(
            characteristicCandidates,
            preferredUuids: preferredCharacteristics
        ) else {
            failConnection("No writable GATT characteristic")
            return
        }

        stopServiceDiscoveryTimer()
        writeCharacteristic = selected.characteristic
        writeType = RapidKitBleCharacteristicSelector.writeType(selected.characteristic.properties)
        let completion = connectCompletion
        connectCompletion = nil
        completion?(true)
    }

    private func writeNextPacket() {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = pendingData else {
            completeWrite(false)
            return
        }

        if writeType == .withoutResponse {
            while peripheral.canSendWriteWithoutResponse {
                guard let packet = nextPacket(from: data) else {
                    completeWrite(true)
                    return
                }
                peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
                currentPacketIndex += 1
            }
            if nextPacket(from: data) == nil { completeWrite(true) }
            return
        }

        guard let packet = nextPacket(from: data) else {
            completeWrite(true)
            return
        }
        peripheral.writeValue(packet, for: characteristic, type: .withResponse)
    }

    private func nextPacket(from data: Data) -> Data? {
        let start = currentPacketIndex * RapidKitBleContext.packetLength
        guard start < data.count else { return nil }
        let end = min(start + RapidKitBleContext.packetLength, data.count)
        return data.subdata(in: start..<end)
    }

    private func completeWrite(_ success: Bool) {
        stopWriteTimer()
        pendingData = nil
        currentPacketIndex = 0
        let completion = writeCompletion
        writeCompletion = nil
        completion?(success)
    }

    private func failConnection(_ reason: String) {
        NSLog("[RapidKitBleContext][failConnection] %@", reason)
        let peripheral = connectedPeripheral
        let pendingConnect = connectCompletion
        connectCompletion = nil
        let pendingWrite = writeCompletion
        writeCompletion = nil
        clearConnectionState()
        if let peripheral = peripheral, peripheral.state != .disconnected {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        pendingConnect?(false)
        pendingWrite?(false)
    }

    private func clearConnectionState() {
        stopConnectTimer()
        stopServiceDiscoveryTimer()
        stopWriteTimer()
        connectedPeripheral = nil
        preferredCharacteristics = nil
        writeCharacteristic = nil
        writeType = .withResponse
        characteristicCandidates.removeAll()
        pendingServices.removeAll()
        pendingData = nil
        currentPacketIndex = 0
    }

    private func startConnectTimer() {
        stopConnectTimer()
        connectTimer = Timer.scheduledTimer(withTimeInterval: RapidKitBleContext.connectTimeout,
                                            repeats: false) { [weak self] _ in
            self?.failConnection("Connection timeout")
        }
    }

    private func stopConnectTimer() {
        connectTimer?.invalidate()
        connectTimer = nil
    }

    private func startServiceDiscoveryTimer() {
        stopServiceDiscoveryTimer()
        serviceDiscoveryTimer = Timer.scheduledTimer(
            withTimeInterval: RapidKitBleContext.serviceDiscoveryTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.failConnection("GATT discovery timeout")
        }
    }

    private func stopServiceDiscoveryTimer() {
        serviceDiscoveryTimer?.invalidate()
        serviceDiscoveryTimer = nil
    }

    private func startWriteTimer() {
        stopWriteTimer()
        writeTimer = Timer.scheduledTimer(withTimeInterval: RapidKitBleContext.writeTimeout,
                                          repeats: false) { [weak self] _ in
            self?.completeWrite(false)
        }
    }

    private func stopWriteTimer() {
        writeTimer?.invalidate()
        writeTimer = nil
    }
}
