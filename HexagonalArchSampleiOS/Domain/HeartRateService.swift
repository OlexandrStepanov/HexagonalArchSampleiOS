//
//  HeartRateService.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/23/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation

protocol HeartRateServiceProtocol {
    var state: HeartRateService.State { get }
    var delegate: HeartRateServiceDelegate? { get set }
    
    func startSyncing() -> Result<Void, HeartRateService.Error>
    func stopSyncing()
}

protocol HeartRateServiceDelegate {
    func stateDidChange(to newState: HeartRateService.State)
    func hasRecorded(record: HeartRateRecord)
}

class HeartRateService: HeartRateServiceProtocol, BluetoothPortDelegate {
    
    enum State {
        case disabled
        case enabled
        case searchingSensor
        case discoveringSensorCharacteristics
        case syncingSensorData
    }
    
    enum Error: Swift.Error {
        case bluetoothIsDisabled
    }
    
    private(set) var state: State {
        didSet {
            self.delegate?.stateDidChange(to: state)
        }
    }
    var delegate: HeartRateServiceDelegate?
    
    private var bluetoothPort: BluetoothPort
    private let storagePort: StoragePort
    
    init(bluetoothPort: BluetoothPort, storagePort: StoragePort) {
        self.bluetoothPort = bluetoothPort
        self.storagePort = storagePort
        
        state = .disabled
        self.bluetoothPort.delegate = self
    }
    
    func startSyncing() -> Result<Void, Error> {
        switch state {
        case .disabled:
            return .failure(.bluetoothIsDisabled)
        case .enabled:
            bluetoothPort.startScanning()
            fallthrough
        case .searchingSensor, .syncingSensorData, .discoveringSensorCharacteristics:
            return .success(())
        }
    }
    
    func stopSyncing() {
        bluetoothPort.stopScanning()
    }
    
    // MARK: BluetoothPortDelegate
    
    func stateDidChange(to newState: BluetoothPortState) {
        switch newState {
        case .disabled(let reason):
            print("Bluetooth disabled: \(reason)")
            state = .disabled
        case .enabled:
            state = .enabled
        case .peripheralConnected:
            state = .discoveringSensorCharacteristics
        case .characteristicDiscovered:
            state = .syncingSensorData
        }
    }
    
    func hasRead(heartRate: Int) {
        let record = HeartRateRecord(value: heartRate)
        storagePort.store(record: record) { [weak self] result in
            switch result {
            case .failure(let error):
                print("HeartRecord \(record) failed to be stored: \(error)")
            case .success:
                self?.delegate?.hasRecorded(record: record)
            }
        }
    }
    
}
