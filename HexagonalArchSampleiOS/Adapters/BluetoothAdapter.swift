//
//  BluetoothAdapter.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/23/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation
import CoreBluetooth

private let BLEHeartRateServiceID = CBUUID(string: "0x180D")
private let BLEHeartRateMeasurementCharacteristicID = CBUUID(string: "0x2A37")

class BluetoothAdapter: NSObject, BluetoothPort {
    
    private lazy var centralManager: CBCentralManager = {
        let centralQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        return CBCentralManager(delegate: self, queue: centralQueue)
    }()
    fileprivate var peripheralHeartRateMonitor: CBPeripheral?
    
    weak var delegate: BluetoothPortDelegate?
    fileprivate(set) var state: BluetoothPortState {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.stateDidChange(to: self.state)
            }
        }
    }
    
    override init() {
        state = .disabled(reason: CBManagerState.unknown.stringValue)
    }
    
    // MARK: BluetoothPort
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: [BLEHeartRateServiceID])
    }
    
    func stopScanning() {
        if let peripheral = peripheralHeartRateMonitor {
            centralManager.cancelPeripheralConnection(peripheral)
            peripheralHeartRateMonitor = nil
        }
        centralManager.stopScan()
    }
    
    // MARK: Private
    
    fileprivate func deriveBeatsPerMinute(using heartRateMeasurementCharacteristic: CBCharacteristic) -> Int {
        let heartRateValue = heartRateMeasurementCharacteristic.value!
        let buffer = [UInt8](heartRateValue)
        
        if ((buffer[0] & 0x01) == 0) {
            return Int(buffer[1])
        }
        
        return -1
    }
}

extension BluetoothAdapter: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            state = .disabled(reason: central.state.stringValue)
        case .poweredOn:
            state = .enabled
        @unknown default:
            state = .disabled(reason: CBManagerState.unknown.stringValue)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // We must store a reference to the just-discovered peripheral to persist it
        peripheralHeartRateMonitor = peripheral
        peripheral.delegate = self
        
        // stop scanning to preserve battery life;
        // re-scan if disconnected
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .peripheralConnected
        peripheralHeartRateMonitor?.discoverServices([BLEHeartRateServiceID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        state = .enabled
        centralManager.scanForPeripherals(withServices: [BLEHeartRateServiceID])
    }
}

extension BluetoothAdapter: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach({ service in
            if service.uuid == BLEHeartRateServiceID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        })
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach({ characteristic in
            if characteristic.uuid == BLEHeartRateMeasurementCharacteristicID {
                state = .characteristicDiscovered
                peripheral.setNotifyValue(true, for: characteristic)
            }
        })
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == BLEHeartRateMeasurementCharacteristicID else { return }
        
        delegate?.hasRead(heartRate: deriveBeatsPerMinute(using: characteristic))
    }
}

extension CBManagerState {
    var stringValue: String {
        switch self {
        case .poweredOff:
            return "Powered off"
        case .poweredOn:
            return "Powered on"
        case .resetting:
            return "Resettings"
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown"
        case .unsupported:
            return "Unsupported"
        @unknown default:
            return "Unknown"
        }
    }
}
