package com.tange.ai.rapid_kit

import android.Manifest.permission
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattCharacteristic.*
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.util.Consumer
import com.tange.ai.rapid.kit.Logging

data class BleDevice(val name: String, val address: String)

class RapidKitBleContext(private val activity: Activity) {

    companion object {
        private const val TAG = "_BleContext_"
        private const val CONNECT_TIMEOUT = 180 * 1000L
        private const val SERVICE_DISCOVERY_TIMEOUT = 10 * 1000L
        private const val WRITE_TIMEOUT = 10000L  // 写入超时
        private const val PACKET_LENGTH = 20  // 数据包长度
        private const val RETRY_DELAY = 3000L
        private const val GATT_ERROR_RETRY_DELAY = 3000L  // Retry delay for GATT errors
        private const val SERVICE_DISCOVERY_INITIAL_DELAY = 5000L  // 连接成功后等待5秒再开始服务发现
        private const val SERVICE_DISCOVERY_RETRY_DELAY = 2000L  // 服务发现失败后重试延迟
        private const val SERVICE_CHECK_DELAY = 1000L  // 服务检查延迟
        private const val MAX_SERVICE_DISCOVERY_RETRIES = 3  // 最大服务发现重试次数

        // GATT Status Code Definitions
        private const val GATT_SUCCESS = BluetoothGatt.GATT_SUCCESS  // 0: Operation successful
        private const val GATT_CONN_TERMINATE_PEER_USER = 22  // Remote device terminated connection
        private const val GATT_CONN_TERMINATE_LOCAL_HOST = 19  // Local host terminated connection
        private const val GATT_CONN_FAIL_ESTABLISH = 62  // Failed to establish connection
        private const val GATT_ERROR = 133  // Connection rejected or device unreachable
        private const val GATT_INTERNAL_ERROR = 257  // Internal error in system Bluetooth stack
        private const val GATT_CONN_TIMEOUT = 8  // Connection timeout
        private const val GATT_INVALID_HANDLE = 1  // Invalid handle
        private const val GATT_READ_NOT_PERMIT = 2  // Read not permitted
        private const val GATT_WRITE_NOT_PERMIT = 3  // Write not permitted
        private const val GATT_INSUFFICIENT_AUTHENTICATION = 5  // Authentication failed
        private const val GATT_REQUEST_NOT_SUPPORTED = 6  // Request not supported
        private const val GATT_INVALID_OFFSET = 7  // Invalid offset
        private const val GATT_INVALID_ATTRIBUTE_LENGTH = 13  // Invalid attribute length
        private const val GATT_INSUFFICIENT_ENCRYPTION = 15  // Insufficient encryption

        private fun getGattStatusDescription(status: Int): String {
            return when (status) {
                GATT_SUCCESS -> "Success"
                GATT_CONN_TERMINATE_PEER_USER -> "Remote device terminated connection"
                GATT_CONN_TERMINATE_LOCAL_HOST -> "Local host terminated connection"
                GATT_CONN_FAIL_ESTABLISH -> "Failed to establish connection"
                GATT_ERROR -> "Connection rejected or device unreachable"
                GATT_INTERNAL_ERROR -> "System Bluetooth stack internal error"
                GATT_CONN_TIMEOUT -> "Connection timeout"
                GATT_INVALID_HANDLE -> "Invalid handle"
                GATT_READ_NOT_PERMIT -> "Read not permitted"
                GATT_WRITE_NOT_PERMIT -> "Write not permitted"
                GATT_INSUFFICIENT_AUTHENTICATION -> "Authentication failed"
                GATT_REQUEST_NOT_SUPPORTED -> "Request not supported"
                GATT_INVALID_OFFSET -> "Invalid offset"
                GATT_INVALID_ATTRIBUTE_LENGTH -> "Invalid attribute length"
                GATT_INSUFFICIENT_ENCRYPTION -> "Insufficient encryption"
                else -> "Unknown error ($status)"
            }
        }
    }

    private fun log(message: String) = Logging.i(TAG, message)

    private val discoveredDevices = mutableSetOf<BleDevice>()
    private val connectTimeoutHandler = Handler(Looper.getMainLooper())
    private val serviceDiscoveryTimeoutHandler = Handler(Looper.getMainLooper())
    private val writeTimeoutHandler = Handler(Looper.getMainLooper())
    private val writePacketHandler = Handler(Looper.getMainLooper())
    private val retryHandler = Handler(Looper.getMainLooper())
    private val serviceDiscoveryHandler = Handler(Looper.getMainLooper())  // 新增服务发现专用Handler
    private val retryConnectHandler = Handler(Looper.getMainLooper())  // 专门用于重试连接的Handler

    private lateinit var bluetoothAdapter: BluetoothAdapter
    private lateinit var bluetoothLeScanner: BluetoothLeScanner
    private var bluetoothGatt: BluetoothGatt? = null
    private var writeCharacteristic: BluetoothGattCharacteristic? = null

    private var isDiscovering: Boolean = false
    private var isWriting: Boolean = false
    private var isConnecting: Boolean = false
    private var retryCount: Int = 0

    private var targetDeviceMacAddress: String? = null
    private var preferWriteCharacteristicsList: List<String>? = null
    private var writeListener: Consumer<Boolean>? = null
    private var connectListener: Consumer<Boolean>? = null

    private var writeData: ByteArray? = null
    private var writeIndex = 0

    private val gattLock = Object()  // Synchronization lock
    private var isCleaningUp = false // Cleanup status flag

    private var serviceDiscoveryRetryCount = 0  // 服务发现重试计数

    private var isActiveDisconnecting = false  // 主动断开连接的标志

    fun prepare() {
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        bluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner
    }

    fun write(data: ByteArray, listener: Consumer<Boolean>?) {
        if (isWriting) {
            log("[Write] Aborted - Write operation already in progress")
            listener?.accept(false)
            return
        }

        log("[Write] Starting write operation - Data length: ${data.size}")
        isWriting = true
        writeData = data
        writeIndex = 0
        writeListener = listener

        writePacketHandler.removeCallbacksAndMessages(null)
        writeTimeoutHandler.removeCallbacksAndMessages(null)
        writeTimeoutHandler.postDelayed({
            log("[Write] Operation timeout")
            writeListener?.accept(false)
            cleanupWrite()
        }, WRITE_TIMEOUT)

        writeNextPacket()
    }

    private fun writeNextPacket() {
        if (writeData == null || writeCharacteristic == null) {
            log("[Write] Aborted - Missing data or characteristic")
            writeListener?.accept(false)
            cleanupWrite()
            return
        }

        if (writeIndex >= writeData!!.size) {
            log("[Write] Completed - All packets sent successfully")
            writeListener?.accept(true)
            cleanupWrite()
            return
        }

        val packetLength = minOf(PACKET_LENGTH, writeData!!.size - writeIndex)
        val packet = writeData!!.copyOfRange(writeIndex, writeIndex + packetLength)
        log("[Write] Sending packet ${writeIndex / PACKET_LENGTH + 1} - Size: $packetLength")

        writeCharacteristic?.value = packet
        if (bluetoothGatt?.writeCharacteristic(writeCharacteristic) == true) {
            writeIndex += packetLength
        } else {
            log("[Write] Failed - Unable to write characteristic")
            writeListener?.accept(false)
            cleanupWrite()
        }
    }

    private fun cleanupWrite() {
        isWriting = false
        writeData = null
        writeIndex = 0
        writeTimeoutHandler.removeCallbacksAndMessages(null)
        writePacketHandler.removeCallbacksAndMessages(null)
    }

    fun isConnected(macAddress: String): Boolean {
        return macAddress == targetDeviceMacAddress && writeCharacteristic != null
    }

    fun connect(
        macAddress: String, characteristicsList: List<String>?, listener: Consumer<Boolean>?
    ) {
        if (isConnecting) {
            log("[Connect] Aborted - Connection already in progress")
            return
        }

        log("[Connect] Initiating connection to device: $macAddress")
        isActiveDisconnecting = false
        isConnecting = true
        retryCount = 0
        writeCharacteristic = null
        connectListener = listener
        preferWriteCharacteristicsList = characteristicsList
        // log preferWriteCharacteristicsList
        log("[Connect] Preferred write characteristics list: $preferWriteCharacteristicsList")
        targetDeviceMacAddress = macAddress

        startConnectTimer()
        connectInternal()
    }

    private fun startConnectTimer() {
        connectTimeoutHandler.removeCallbacksAndMessages(null)
        connectTimeoutHandler.postDelayed({
            log("[Connect] Connection timeout reached")
            handleConnectTimeout()
        }, CONNECT_TIMEOUT)
    }

    private fun handleConnectTimeout() {
        log("[Connect] Handling connection timeout")
        disconnectInternal()
        cleanupConnection(true)
    }

    private fun startServiceDiscoveryTimer() {
        serviceDiscoveryTimeoutHandler.removeCallbacksAndMessages(null)
        serviceDiscoveryTimeoutHandler.postDelayed({
            log("[ServiceDiscovery] Discovery timeout reached")
            handleServiceDiscoveryTimeout()
        }, SERVICE_DISCOVERY_TIMEOUT)
    }

    private fun handleServiceDiscoveryTimeout() {
        log("[ServiceDiscovery] Handling discovery timeout")
        bluetoothGatt?.let { gatt ->
            retryServiceDiscovery(gatt)
        } ?: run {
            log("[ServiceDiscovery] No GATT instance available - Retrying connection")
            retryConnection()
        }
    }

    private fun resetBluetoothAdapter() {
        try {
            log("[BluetoothAdapter] Resetting adapter")
            bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            bluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner
            Thread.sleep(500)
            log("[BluetoothAdapter] Reset completed")
        } catch (e: Exception) {
            log("[BluetoothAdapter] Failed to reset adapter")
        }
    }

    private fun ensureConnectionCleanup() {
        synchronized(gattLock) {
            if (isCleaningUp) {
                log("[Cleanup] Already in progress")
                return
            }
            isCleaningUp = true
            
            log("[Cleanup] Starting connection cleanup")
            try {
                // Clean up all delayed tasks
                retryConnectHandler.removeCallbacksAndMessages(null)
                retryHandler.removeCallbacksAndMessages(null)
                serviceDiscoveryTimeoutHandler.removeCallbacksAndMessages(null)
                serviceDiscoveryHandler.removeCallbacksAndMessages(null)
                writeTimeoutHandler.removeCallbacksAndMessages(null)
                writePacketHandler.removeCallbacksAndMessages(null)
                
                // Clean up GATT connection
                bluetoothGatt?.let { gatt ->
                    try {
                        gatt.disconnect()
                        Thread.sleep(100)
                        gatt.close()
                        Thread.sleep(100)
                        log("[Cleanup] GATT connection closed")
                    } catch (e: Exception) {
                        log("[Cleanup] Error during GATT cleanup")
                    }
                }
                bluetoothGatt = null
                writeCharacteristic = null
                
                Thread.sleep(200)
                log("[Cleanup] Connection cleanup completed")
            } finally {
                isCleaningUp = false
            }
        }
    }

    private fun retryConnection() {
        if (targetDeviceMacAddress == null) {
            log("[BLE] 重试失败 - 设备地址未找到")
            cleanupConnection(true)
            return
        }

        log("[BLE] 准备重试连接")
        
        // 清理所有可能的延时任务
        retryConnectHandler.removeCallbacksAndMessages(null)
        serviceDiscoveryHandler.removeCallbacksAndMessages(null)
        serviceDiscoveryTimeoutHandler.removeCallbacksAndMessages(null)
        
        // 确保清理旧连接
        ensureConnectionCleanup()
        
        // 延迟后重试
        retryConnectHandler.postDelayed({
            synchronized(gattLock) {
                if (!isCleaningUp) {
                    log("[BLE] 执行重试")
                    connectInternal()
                } else {
                    log("[BLE] 由于正在清理,跳过重试")
                }
            }
        }, RETRY_DELAY)
    }

    private fun connectInternal() {
        synchronized(gattLock) {
            if (isCleaningUp) {
                log("[BLE] 清理过程中无法连接")
                return
            }
            
            val deviceAddress = targetDeviceMacAddress
            if (deviceAddress == null) {
                log("[BLE] 无法连接 - 设备地址为空")
                cleanupConnection(true)
                return
            }
            
            try {
                val device = bluetoothAdapter.getRemoteDevice(deviceAddress)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    bluetoothGatt = device.connectGatt(activity, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
                } else {
                    bluetoothGatt = device.connectGatt(activity, false, gattCallback)
                }
                
                bluetoothGatt?.let { gatt ->
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        gatt.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH)
                    }
                }
                log("[BLE] 开始连接: GATT = $bluetoothGatt")
            } catch (e: Exception) {
                log("[BLE] 创建GATT连接失败")
                cleanupConnection()
            }
        }
    }

    fun disconnect() {
        log("[Disconnect] Initiating active disconnection")
        connectTimeoutHandler.removeCallbacksAndMessages(null)
        synchronized(gattLock) {
            isActiveDisconnecting = true
            disconnectInternal()
            cleanupConnection()
        }
    }

    private fun disconnectInternal() {
        bluetoothGatt?.let { gatt ->
            try {
                gatt.disconnect()
                Thread.sleep(100)
                gatt.close()
                log("[Disconnect] GATT connection closed")
            } catch (e: Exception) {
                log("[Disconnect] Error during disconnection")
            }
        }
        bluetoothGatt = null
    }

    private fun cleanupConnection(notifyResult: Boolean = false) {
        synchronized(gattLock) {
            log("[Cleanup] Starting connection cleanup (notifyResult: $notifyResult)")
            isConnecting = false
            writeCharacteristic = null
            bluetoothGatt = null
            
            // Clean up all handlers
            serviceDiscoveryTimeoutHandler.removeCallbacksAndMessages(null)
            serviceDiscoveryHandler.removeCallbacksAndMessages(null)
            retryHandler.removeCallbacksAndMessages(null)
            retryConnectHandler.removeCallbacksAndMessages(null)
            cleanupWrite()
            
            if (notifyResult) {
                log("[Cleanup] Clearing device information")
                targetDeviceMacAddress = null
                preferWriteCharacteristicsList = null
                connectListener?.accept(false)
            }
            
            log("[Cleanup] Connection cleanup completed")
        }
    }

    fun startDiscovery() {
        if (isDiscovering) return
        log("[Discovery] Starting device discovery")
        isDiscovering = true
        discoveredDevices.clear()
        bluetoothLeScanner.startScan(scanCallback)
    }

    fun stopDiscovery() {
        if (!isDiscovering) return
        log("[Discovery] Stopping device discovery")
        isDiscovering = false
        bluetoothLeScanner.stopScan(scanCallback)
    }

    fun nearbyDevices(): Set<BleDevice> = discoveredDevices

    fun isBluetoothEnabled(): Boolean {
        val enabled = bluetoothAdapter.isEnabled
        log("[Bluetooth] Adapter state: ${if (enabled) "enabled" else "disabled"}")
        return enabled
    }

    fun permissionGranted(): Boolean {
        var granted = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            granted = ActivityCompat.checkSelfPermission(
                activity, permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                activity, permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            granted = ActivityCompat.checkSelfPermission(
                activity, permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            granted = true
        }
        log("[Permission] Bluetooth permission state: ${if (granted) "granted" else "denied"}")
        return granted
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            super.onScanResult(callbackType, result)
            if (!isDiscovering) return
            val device = result.device
            val name = device.name ?: ""
            val address = device.address
            if (discoveredDevices.none { it.address == address }) {
                log("[Discovery] New device found - Name: $name, Address: $address")
                discoveredDevices.add(BleDevice(name, address))
            }
        }
    }

    private fun logGattError(operation: String, status: Int) {
        log("[GATT] $operation failed: ${getGattStatusDescription(status)} (Status: $status)")
    }

    private fun startServiceDiscovery(gatt: BluetoothGatt) {
        serviceDiscoveryRetryCount = 0
        startServiceDiscoveryInternal(gatt)
    }

    private fun startServiceDiscoveryInternal(gatt: BluetoothGatt) {
        startServiceDiscoveryTimer()
        log("[ServiceDiscovery] Starting discovery (Attempt ${serviceDiscoveryRetryCount + 1})")
        gatt.discoverServices()
    }

    private fun retryServiceDiscovery(gatt: BluetoothGatt) {
        serviceDiscoveryRetryCount++
        if (serviceDiscoveryRetryCount < MAX_SERVICE_DISCOVERY_RETRIES) {
            log("[ServiceDiscovery] Scheduling retry in ${SERVICE_DISCOVERY_RETRY_DELAY}ms (Attempt ${serviceDiscoveryRetryCount + 1})")
            serviceDiscoveryHandler.removeCallbacksAndMessages(null)
            serviceDiscoveryHandler.postDelayed({
                startServiceDiscoveryInternal(gatt)
            }, SERVICE_DISCOVERY_RETRY_DELAY)
        } else {
            log("[ServiceDiscovery] Max retry attempts reached - Retrying connection")
            retryConnection()
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            super.onConnectionStateChange(gatt, status, newState)
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    if (status == GATT_SUCCESS) {
                        log("[Connection] Success - Starting service discovery in ${SERVICE_DISCOVERY_INITIAL_DELAY}ms")
                        refreshDeviceCache(gatt)
                        serviceDiscoveryHandler.removeCallbacksAndMessages(null)
                        serviceDiscoveryHandler.postDelayed({
                            val currentGatt = bluetoothGatt
                            if (currentGatt != null) {
                                startServiceDiscovery(currentGatt)
                            } else {
                                log("[Connection] No available GATT instance")
                                retryConnection()
                            }
                        }, SERVICE_DISCOVERY_INITIAL_DELAY)
                    } else {
                        logGattError("Connection", status)
                        retryConnection()
                    }
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    serviceDiscoveryHandler.removeCallbacksAndMessages(null)
                    if (!isActiveDisconnecting) {
                        if (status == GATT_INTERNAL_ERROR) {
                            log("[Connection] Internal error detected - Resetting Bluetooth adapter")
                            resetBluetoothAdapter()
                        }
                        retryConnection()
                    } else {
                        log("[Connection] Active disconnection completed")
                    }
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            super.onServicesDiscovered(gatt, status)
            if (status == GATT_SUCCESS) {
                log("[ServiceDiscovery] Services discovered successfully")
                serviceDiscoveryTimeoutHandler.removeCallbacksAndMessages(null)
                
                Handler(Looper.getMainLooper()).postDelayed({
                    val services = gatt?.services
                    log("[ServiceDiscovery] Found ${services?.size ?: 0} services")
                    
                    if (services.isNullOrEmpty()) {
                        log("[ServiceDiscovery] No services found - Retrying discovery")
                        gatt?.let { 
                            if (refreshDeviceCache(it)) {
                                retryServiceDiscovery(it)
                            } else {
                                log("[ServiceDiscovery] Cache refresh failed - Retrying discovery")
                                retryServiceDiscovery(it)
                            }
                        }
                        return@postDelayed
                    }
                    
                    discoverWriteCharacteristic()
                }, SERVICE_CHECK_DELAY)
            } else {
                logGattError("Service discovery", status)
                gatt?.let { 
                    refreshDeviceCache(it)
                    retryServiceDiscovery(it)
                }
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            super.onCharacteristicWrite(gatt, characteristic, status)
            if (status == GATT_SUCCESS) {
                log("[Write] Packet ${writeIndex / PACKET_LENGTH + 1} written successfully")
                writeNextPacket()
            } else {
                logGattError("Characteristic write", status)
                writeListener?.accept(false)
                cleanupWrite()
            }
        }
    }

    private fun discoverWriteCharacteristic() {
        val services = bluetoothGatt?.services
        log("[CharacteristicDiscovery] Services status - Available: ${services != null}, Count: ${services?.size ?: 0}")
        
        if (services.isNullOrEmpty()) {
            log("[CharacteristicDiscovery] No services found - Retrying connection")
            retryConnection()
            return
        }

        log("[CharacteristicDiscovery] Processing ${services.size} services")
        val candidates = mutableListOf<RapidKitBleCharacteristicSelector.Candidate>()
        val candidateCharacteristics = mutableListOf<BluetoothGattCharacteristic>()

        for (service in services) {
            log("[CharacteristicDiscovery] Service - UUID: ${service.uuid}, Primary: ${service.type == BluetoothGattService.SERVICE_TYPE_PRIMARY}")
            
            for (characteristic in service.characteristics) {
                val uuid = characteristic.uuid.toString()
                val properties = characteristic.properties
                val score = RapidKitBleCharacteristicSelector.calculateScore(properties)
                val flags = RapidKitBleCharacteristicSelector.formatProperties(properties)
                log("[CharacteristicDiscovery] Characteristic - UUID: $uuid, Properties: $properties, Flags: $flags, Score: $score")

                candidates.add(
                    RapidKitBleCharacteristicSelector.Candidate(
                        uuid = uuid,
                        properties = properties,
                        serviceUuid = service.uuid.toString(),
                        index = candidateCharacteristics.size
                    )
                )
                candidateCharacteristics.add(characteristic)
            }
        }

        val selection = RapidKitBleCharacteristicSelector.select(candidates, preferWriteCharacteristicsList)
        if (selection == null) {
            log("[CharacteristicDiscovery] No writable characteristic found")
            retryConnection()
            return
        }

        val selectedCharacteristic = candidateCharacteristics[selection.candidate.index]
        selectedCharacteristic.writeType = if (RapidKitBleCharacteristicSelector.prefersWriteNoResponse(selection.candidate.properties)) {
            WRITE_TYPE_NO_RESPONSE
        } else {
            WRITE_TYPE_DEFAULT
        }
        writeCharacteristic = selectedCharacteristic
        log(
            "[CharacteristicDiscovery] Selected ${selection.reason.name.lowercase()} characteristic: " +
                "uuid=${selection.candidate.uuid}, service=${selection.candidate.serviceUuid}, " +
                "flags=${RapidKitBleCharacteristicSelector.formatProperties(selection.candidate.properties)}, " +
                "score=${selection.score}, writeType=${selectedCharacteristic.writeType}"
        )
        notifyConnectionSuccess()
    }

    private fun notifyConnectionSuccess() {
        log("[NotifyConnectionSuccess] Notifying connection success ============")
        connectTimeoutHandler.removeCallbacksAndMessages(null)
        isConnecting = false
        val listener = connectListener
        connectListener = null
        listener?.accept(true)
    }

    private fun refreshDeviceCache(gatt: BluetoothGatt): Boolean {
        if (gatt == null) {
            log("[CacheRefresh] Aborted - GATT instance is null")
            return false
        }

        return try {
            log("[CacheRefresh] Attempting to refresh device cache")
            
            // 尝试获取refresh方法
            val refreshMethod = try {
                gatt.javaClass.getMethod("refresh")
            } catch (e: Exception) {
                log("[CacheRefresh] Method not found - Device might not support cache refresh")
                return false
            }

            // 检查方法返回类型
            if (refreshMethod.returnType != Boolean::class.java) {
                log("[CacheRefresh] Unexpected return type: ${refreshMethod.returnType}")
                return false
            }

            // 执行刷新
            val result = try {
                refreshMethod.invoke(gatt) as? Boolean ?: false
            } catch (e: Exception) {
                log("[CacheRefresh] Failed to invoke refresh method")
                return false
            }

            log("[CacheRefresh] Cache refresh ${if (result) "successful" else "failed"}")
            
            if (result) {
                try {
                    // 给设备一些时间清理缓存
                    Thread.sleep(200)
                } catch (e: InterruptedException) {
                    log("[CacheRefresh] Sleep interrupted during cache clearing")
                }
            }
            
            result
        } catch (e: Throwable) {
            // 捕获所有可能的异常，包括Error
            log("[CacheRefresh] Unexpected error during cache refresh")
            false
        }
    }
}
