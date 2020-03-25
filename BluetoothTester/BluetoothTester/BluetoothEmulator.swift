//
//  BluetoothEmulator.swift
//  BluetoothTester
//
//  Created by Bjørn Inge Berg on 23/03/2020.
//  Copyright © 2020 Bjørn Inge Berg. All rights reserved.
//

import CoreBluetooth
import IOBluetooth

class BluetoothEmulator: NSObject, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    fileprivate let primaryService = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let writeCharachteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let notifyCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    fileprivate var writeCharacteristics: CBMutableCharacteristic!
    fileprivate var notifyCharacteristics: CBMutableCharacteristic!

    private lazy var service: CBMutableService = CBMutableService(type: primaryService, primary: true)

    //this timer makes sure we send bubbleInfo every 300 seconds to wake up the central
    private var timer: RepeatingTimer?

    //this is just a reasonable default.
    //It will be updated later with the value from the central
    private var mtu: Int = 25
    private var peripheralManager: CBPeripheralManager!

    private let managerQueue = DispatchQueue(label: "no.bjorninge.bluetoothManagerQueue", qos: .utility)

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        NSLog("State updated to: \(peripheral.stateDesc)")

        if peripheral.state == .poweredOn {
            startAdvertising()
        } else {
            stopAdvertising()
            NSLog("Bluetooth not on, aborting")
        }
    }

    func stopAdvertising() {
        NSLog("Stopping advertising")
        peripheralManager.stopAdvertising()
    }

    func startAdvertising() {

        if let deviceName = Host.current().localizedName {
           NSLog("Starting advertising on computer \(deviceName)")
        }

        guard let localName = IOBluetoothHostController().nameAsString(), localName.lowercased().starts(with: "bubble") else {
            fatalError("Computer name must be changed to 'Bubble_fake' before running this program. Then restart bluetooth or computer to make it work!")
        }

        NSLog("Starting advertising with local name \(localName)")

        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: localName,
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]

        ]

        peripheralManager.removeAllServices()
        peripheralManager.add(service)
        peripheralManager.startAdvertising(advertisementData)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        NSLog("Added service: \(service.description), error? \(String(describing: error))")
    }

    override init() {

        super.init()

        let permissions: CBAttributePermissions = [.readable, .writeable]
        self.writeCharacteristics = CBMutableCharacteristic(type: writeCharachteristicUUID, properties: [.writeWithoutResponse, .write], value: nil, permissions: permissions)
        self.notifyCharacteristics = CBMutableCharacteristic(type: notifyCharacteristicUUID, properties: [.writeWithoutResponse, .write, .notify], value: nil, permissions: permissions)

        self.service.characteristics = [writeCharacteristics, notifyCharacteristics]

        NSLog("Initing BluetoothEmulator")

        managerQueue.sync {
            self.peripheralManager = CBPeripheralManager(delegate: self, queue: managerQueue)
            //peripheralManager.delegate = self
            NSLog(self.peripheralManager.stateDesc)
        }

    }
    deinit {
        stopAdvertising()
        self.timer = nil
        peripheralManager = nil
        NSLog("Deiniting BluetoothEmulator")

    }

    func periodicWakeupCentral(timeInterval: TimeInterval = 300) {
        NSLog("Setting periodic data transfer to : \(timeInterval) seconds")
        self.timer = RepeatingTimer(timeInterval: timeInterval)
        self.timer?.eventHandler = {
            self.managerQueue.sync {
                NSLog("periodicSendSensorData Timer Fired")
                self.sendBubbleInfo()
                //self.sendSerialNumber()
                //self.sendSensorData()
            }

        }
        self.timer?.resume()
    }

    func sendSerialNumber() {
        let serial = BubbleTx.formatSerialNumber()

        updateNotifyCharacteristicsInBatch(batch: serial)

    }

    func sendSensorData(sensorData: SensorData = LibreOOPDefaults.TestPatchDataAlwaysReturning63 ) {

        NSLog("sendSensorData")
        let sequence = sensorData.bytes

        var batches = [Data]()

        //sensorData = SensorData(uuid: Data(rxBuffer.subdata(in: 5..<13)), bytes: [UInt8](rxBuffer.subdata(in: 18..<362)), date: Date())
        let advanceBy = mtu - BubbleTx.dataPacketPrefixLength

        for idx in stride(from: sequence.indices.lowerBound, to: sequence.indices.upperBound, by: advanceBy) {
            let subsequence = sequence[idx..<min(idx.advanced(by: advanceBy), sequence.count)]
            let data = BubbleTx.formatDataPacket(sequence: Array(subsequence), mtu: mtu)

            batches.append(data)

        }
        updateNotifyCharacteristicsInBatch(batches: batches)

        NSLog("completed sendSensorData")
        //self.notifyCharacteristics.value = data

    }

    func sendBubbleInfo() {
        let info = BubbleTx.formatBubbleInfo()
        updateNotifyCharacteristicsInBatch(batch: info)

    }

    func updateNotifyCharacteristics(_ data: Data) -> Bool {
        peripheralManager.updateValue(data, for: notifyCharacteristics, onSubscribedCentrals: nil)
    }

    /*

 to support retransmit of large sets of data

     **/

    private var sendDataQueue = [Data]()
    private let lockQueue = DispatchQueue(label: "com.test.LockQueue")

    func updateNotifyCharacteristicsInBatch(batch: Data) {
        updateNotifyCharacteristicsInBatch(batches: [batch])
    }
    func updateNotifyCharacteristicsInBatch(batches: [Data]) {
           // Change to your data
          for data in batches {
              lockQueue.sync {
                  sendDataQueue.append(data)
              }
          }
          processNotifyCharacteristicsUpdate()
    }

    func processNotifyCharacteristicsUpdate() {
          guard let characteristicData = sendDataQueue.first else {
              return
          }
          while updateNotifyCharacteristics(characteristicData) {
              lockQueue.sync {
                  _ = sendDataQueue.remove(at: 0)
                  if sendDataQueue.first == nil {
                      return
                  }
              }
          }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
          processNotifyCharacteristicsUpdate()
    }

}

extension BluetoothEmulator {

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        NSLog("peripheralManagerDidStartAdvertising")
        //stopAdvertising()

    }

    // Listen to dynamic values
    // Called when CBPeripheral .setNotifyValue(true, for: characteristic) is called from the central
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        NSLog("\ndidSubscribeTo characteristic")
        mtu = central.maximumUpdateValueLength

    }
    // Read static values
    // Called when CBPeripheral .readValue(for: characteristic) is called from the central
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        NSLog("\ndidReceiveRead request")

        peripheralManager.respond(to: request, withResult: .success)

    }

    /*
     dabear:: bubble responsestate is of type bubbleinfo
     dabear:: bubble responsestate is of type serialnumber
     dabear:: bubble responsestate is of type datapacket
     dabear:: bubble responsestate is of type datapacket..N

     **/

    // Called when receiving writing from Central.
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        NSLog("\ndidReceiveWrite requests")
        guard let first = requests.first else {
            NSLog("no request")
            return
        }

        requests.forEach { req in

            NSLog("characteristic write request received for \(req.characteristic.uuid.uuidString)")
            NSLog("request value = \(req.value.debugDescription)")
            NSLog("request value decoded: \(req.value?.toDebugString())")

            //self.notifyCharacteristics.value = req.value
            if let value = req.value, let first = value.first {
                if value.count == 3 && first == 0x00 {
                    //var frequencyInterval = value[2]
                    //requestData, reset notifybuffer
                    NSLog("simulator: got requestdata request")

                    self.notifyCharacteristics.value = nil
                    sendBubbleInfo()

                } else if value.count == 6 && first == 0x02 {
                    //bubbleinfo ack with appid as value[5]
                    let appId = value[5]
                    NSLog("simulator: got bubbleinfo ack with appid \(appId)")
                    sendSerialNumber()
                    sendSensorData()

                    if self.timer == nil {
                        periodicWakeupCentral()
                    }

                }
            }

        }

        peripheralManager.respond(to: first, withResult: .success)

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {

        timer = nil
        NSLog("\ndidUnsubscribeFrom characteristic")

    }

}
extension CBPeripheralManager {
    var stateDesc: String {
        switch self.state {
        case .poweredOff:
            return "poweredoff"
        case .poweredOn:
            return "poweredOn"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unknown:
            return "unknown"
        case .unsupported:
            return "unsupported"
        }
    }
}
