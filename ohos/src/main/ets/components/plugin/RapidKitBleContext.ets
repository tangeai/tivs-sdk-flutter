import { Log, MethodResult } from '@ohos/flutter_ohos';
import { ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { access } from '@kit.ConnectivityKit';
import { constant } from '@kit.ConnectivityKit';
import * as rapidPermission from './RapidKitPermission'

// const BLUETOOTH_PERMISSION: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH']
const BLUETOOTH_PERMISSION: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH', 'ohos.permission.USE_BLUETOOTH', 'ohos.permission.DISCOVER_BLUETOOTH']

interface IBleDevice {
  name: string;
  address: string;
}

class BleDevice {
  address: string;
  name: string;

  constructor(address: string, name: string) {
    this.address = address;
    this.name = name;
  }
}

type RapidBleResultListener = (result: boolean) => void;

export class RapidKitBleContext {
  private readonly TAG = 'RapidKitBleContext'
  private readonly EVENT_TYPE_CONNECT_STATE = 'BLEConnectionStateChange'
  private readonly EVENT_TYPE_FIND_DEVICE = 'BLEDeviceFind'
  private readonly SERVICE_TIMEOUT_DURATION = 5 * 1000
  private readonly CONNECT_TIMEOUT_DURATION = 30 * 1000
  private readonly WRITE_TIMEOUT_DURATION = 30 * 1000
  private readonly FIND_DEVICE_INTERVAL = 5 * 1000
  private readonly WRITE_PACKET_LENGTH = 100;
  private readonly MAX_SERVICE_DISCOVER_TIME = 5
  private targetDeviceMacAddress: string | null = null;
  private gattClient: ble.GattClientDevice | null = null;
  private connectState: ble.ProfileConnectionState = 0;
  private targetCharacteristics: Set<string> | null = null;
  private writeServiceUUID: string | null = null;
  private writeCharacteristicsUUID: string | null = null;
  private writeDescriptorUUID: string | null = null;
  private writeData: Uint8Array | null = null;
  private writeIndex: number = 0;
  private readonly discoveredDevices: Map<string, BleDevice> = new Map<string, BleDevice>();
  private writeListener: RapidBleResultListener | null = null
  private connectListener: RapidBleResultListener | null = null
  private connectTimeoutId?: number = undefined
  private writeTimeoutId?: number = undefined
  private serviceTimeoutId?: number = undefined
  private discoverServiceAttempt: number = 0
  private requireConnect = false

  onConnectStateChanged = (stateInfo: ble.BLEConnectionChangeState) => {
    if (stateInfo.deviceId != this.targetDeviceMacAddress) return
    if (!this.requireConnect) return
    console.info(this.TAG, "[connect_state_changed] " + stateInfo.state)
    this.connectState = stateInfo.state
    if (constant.ProfileConnectionState.STATE_CONNECTED == stateInfo.state) {
      console.info(this.TAG, "[connect_state_changed]   -- STATE_CONNECTED")
      this.discoverService()
    }
  }

  onScanResultEvent = (data: Array<ble.ScanResult>) => {
    data.forEach((result) => {
      let name = result.deviceName ?? "";
      let mac = result.deviceId ?? "";
      if (name.trim() != '' && !this.discoveredDevices.has(mac)) {
        this.discoveredDevices.set(mac, new BleDevice(mac, name));
        console.info(this.TAG, " ---> add device: " + mac + " - " + name)
      }
    });
  }

  public write(data: Uint8Array, listener: RapidBleResultListener) {
    if (!this.writeServiceUUID) {
      console.error(this.TAG, '[write] not connected.');
      listener(false)
      return;
    }

    this.cancelWriteTimeout()
    this.writeTimeoutId = setTimeout(() => {
      if (this.writeListener) this.writeListener(false)
    }, this.WRITE_TIMEOUT_DURATION)
    this.writeListener = listener
    this.writeIndex = 0
    this.writeData = data
    this.writeNextPacket()
  }

  public startDiscovery() {
    this.discoveredDevices.clear();
    ble.on(this.EVENT_TYPE_FIND_DEVICE, this.onScanResultEvent);
    let scanOptions: ble.ScanOptions = {
      interval: 1000,
      dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
      matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
    }
    ble.startBLEScan(null, scanOptions)
    console.info(this.TAG, "[startDiscovery]")
  }

  public stopDiscovery() {
    ble.stopBLEScan();
    ble.off(this.EVENT_TYPE_FIND_DEVICE, this.onScanResultEvent)
    console.info(this.TAG, "[stopDiscovery]")
  }

  public isEnabled(): boolean {
    return access.getState() == access.BluetoothState.STATE_ON
  }

  public nearbyDevices(): IBleDevice[] {
    const devicesArray: IBleDevice[] = [];
    this.discoveredDevices.forEach((device, mac) => {
      devicesArray.push({
        name: device.name,
        address: mac
      });
    });
    return devicesArray;
  }

  public acquirePermission(context: Context) {
    abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, BLUETOOTH_PERMISSION).then((data) => {
    })
  }

  public permissionGranted(listener: RapidBleResultListener) {
    rapidPermission.checkAccessToken(BLUETOOTH_PERMISSION[0]).then((grantStatus) => {
      let granted0: boolean = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      listener(granted0)
    })
  }

  public connect(mac: string, characteristics: Array<string>, listener: RapidBleResultListener) {
    console.info(this.TAG, "[connect] ...")
    this.requireConnect = true
    this.targetCharacteristics?.clear()
    this.targetCharacteristics = new Set<string>()
    if (characteristics != null) {
        characteristics.forEach(value => {
          console.info(this.TAG, "[connect]  -- target characteristics: " + value)
          this.targetCharacteristics?.add(value.toUpperCase())
        })
    } else {
      console.info(this.TAG, "[connect] custom characteristics null.")
    }
    
    this.discoverServiceAttempt = 0
    this.connectListener = listener;
    this.targetDeviceMacAddress = mac;

    this.connectInternal()
  }

  public disconnect() {
    console.info(this.TAG, "[disconnect] ...")
    this.requireConnect = false
    this.connectListener = null
    this.targetDeviceMacAddress = null
    this.cancelServiceTimeout()
    this.cancelConnectTimeout()
    this.discoverServiceAttempt = this.MAX_SERVICE_DISCOVER_TIME
    this.disconnectInternal()
  }

  private disconnectInternal() {
    console.info(this.TAG, "[disconnectInternal] ...")
    if (this.gattClient == null) return
    this.gattClient.off(this.EVENT_TYPE_CONNECT_STATE, this.onConnectStateChanged)
    if (this.connectState == constant.ProfileConnectionState.STATE_CONNECTED) this.gattClient.disconnect()
    this.gattClient.close()
    this.gattClient = null
    this.writeServiceUUID = null
    this.connectState = constant.ProfileConnectionState.STATE_DISCONNECTED
  }

  private connectInternal() {
    console.info(this.TAG, "[connectInternal] ...")
    if (this.discoverServiceAttempt >= this.MAX_SERVICE_DISCOVER_TIME) {
      console.info(this.TAG, "[connectInternal] reach max attempt")
      return;
    }
    this.gattClient = ble.createGattClientDevice(this.targetDeviceMacAddress!);
    this.cancelConnectTimeout()
    this.connectTimeoutId = setTimeout(() => {
      if (!this.requireConnect) return
      console.info(this.TAG, "[connect] timeout")
      if (this.connectListener) this.connectListener(false)
      this.disconnect()
    }, this.CONNECT_TIMEOUT_DURATION)

    this.gattClient.on(this.EVENT_TYPE_CONNECT_STATE, this.onConnectStateChanged);
    this.gattClient.connect();
  }

  private cancelConnectTimeout() {
    if (this.connectTimeoutId === undefined) return;
    clearTimeout(this.connectTimeoutId)
    this.connectTimeoutId = undefined
  }

  private cancelServiceTimeout() {
    if (this.serviceTimeoutId === undefined) return;
    clearTimeout(this.serviceTimeoutId)
    this.serviceTimeoutId = undefined
  }

  private cancelWriteTimeout() {
    if (this.writeTimeoutId === undefined) return;
    clearTimeout(this.writeTimeoutId)
    this.writeTimeoutId = undefined
  }

  private discoverService() {
    if (!this.gattClient) return;
    if (this.discoverServiceAttempt >= this.MAX_SERVICE_DISCOVER_TIME) {
      console.info(this.TAG, "[discoverService] reach max attempt")
      return;
    }

    this.discoverServiceAttempt++
    this.cancelServiceTimeout()
    this.serviceTimeoutId = setTimeout(() => {
      if (!this.requireConnect) {
        console.info(this.TAG, "[discoverService] timeout, but no more required.")
        return
      }

      console.info(this.TAG, "[discoverService] timeout, retry with a new connection.")
      this.disconnectInternal()
      this.connectInternal()
    }, this.SERVICE_TIMEOUT_DURATION)

    console.info(this.TAG, "[discoverService] ...")

    let firstWriteServiceUuid: string | null = null
    let firstWriteCharacteristicUuid: string | null = null
    let firstWriteDescriptorUuid: string | null = null

    this.gattClient.getServices().then((services: Array<ble.GattService>) => {
      console.info(this.TAG, "[discoverService] got " + services.length + " services")

      if (!this.requireConnect) {
        console.info(this.TAG, "[discoverService] ignore out-of-date response")
        return
      }

      if (services.length <= 0) {
        console.info(this.TAG, "[discoverService] got " + services.length + " services")
        return
      }

      if (this.writeServiceUUID != null) {
        console.info(this.TAG, "[discoverService] ignore duplicate response")
        return
      }

      console.info(this.TAG, "[discoverService] got services: " + services.length)

      this.cancelServiceTimeout()

      for (const service of services) {
        const servicesUuid = service.serviceUuid.toUpperCase();
        console.info(this.TAG, "[discoverService] -- service: " + servicesUuid)

        for (const characteristic of service.characteristics) {
          const characteristicUuid = characteristic.characteristicUuid.toUpperCase();
          let writeable = characteristic.properties?.write == true
          console.info(this.TAG, "[discoverService]   -- characteristic: " + characteristicUuid + ", writeable = " + writeable)
          for (const descriptor of characteristic.descriptors) {
            const descriptorUuid = descriptor.descriptorUuid.toUpperCase();
            console.info(this.TAG, "[discoverService]     -- descriptor: " + descriptorUuid)

            if (writeable && firstWriteServiceUuid == null) {
              firstWriteServiceUuid = servicesUuid;
              firstWriteCharacteristicUuid = characteristicUuid;
              firstWriteDescriptorUuid = descriptorUuid;
            }

            if (this.writeServiceUUID == null && writeable && this.targetCharacteristics?.has(characteristicUuid)) {
              console.info(this.TAG, "[discoverService]     -- [ NOTICE: hit with client required characteristics ]")
              this.writeServiceUUID = servicesUuid;
              this.writeCharacteristicsUUID = characteristicUuid;
              this.writeDescriptorUUID = descriptorUuid;
            }
          }
        }
      }

      if (this.writeServiceUUID == null && firstWriteServiceUuid != null) {
        this.writeServiceUUID = firstWriteServiceUuid;
        this.writeCharacteristicsUUID = firstWriteCharacteristicUuid;
        this.writeDescriptorUUID = firstWriteDescriptorUuid;
        console.info(this.TAG, "[discoverService] no hit, use first writeable characteristic")
      }

      this.cancelConnectTimeout();
      const ret = this.writeServiceUUID != null
      if (this.connectListener) this.connectListener(ret);

      console.info(this.TAG, "[discoverService] done, success: " + ret)

    }).catch((err: BusinessError) => {
      console.error(`Failed on discover service: ${err.code}, message is ${err.message}`);
    });
  }

  private writeNextPacket(): void {
    if (!this.writeData) {
      return
    }
    if (this.writeIndex >= this.writeData!.byteLength) {
      if (this.writeListener) {
        this.writeListener(true)
      }
      this.cancelWriteTimeout()
      return
    }

    const end = Math.min(this.writeIndex + this.WRITE_PACKET_LENGTH, this.writeData!.byteLength)
    const segment = this.writeData!.slice(this.writeIndex, end).buffer

    let descriptors: Array<ble.BLEDescriptor> = [];
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.writeServiceUUID!,
      characteristicUuid: this.writeCharacteristicsUUID!,
      descriptorUuid: this.writeDescriptorUUID!,
      descriptorValue: segment
    };
    descriptors[0] = descriptor;

    let characteristic: ble.BLECharacteristic = {
      serviceUuid: descriptor.serviceUuid,
      characteristicUuid: descriptor.characteristicUuid,
      characteristicValue: segment,
      descriptors: descriptors
    };

    this.gattClient!.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, (code) => {
      if (code) {
        let error = code as BusinessError
        console.error(this.TAG, 'write error:' + error.code + ', ' + error.message);
        return;
      }
      this.writeIndex = end;
      this.writeNextPacket();
    });
  }
}