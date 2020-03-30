//
//  HeartRateService.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/23/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol HeartRateServiceProtocol {
    var state: BehaviorRelay<HeartRateService.State> { get }
    var heartRate: PublishSubject<HeartRateRecord> { get }
    
    func startSyncing() -> Result<Void, HeartRateService.Error>
    func stopSyncing()
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
    
    let state: BehaviorRelay<State>
    let heartRate = PublishSubject<HeartRateRecord>()
    
    private var bluetoothPort: BluetoothPort
    private let storagePort: StoragePort
    
    init(bluetoothPort: BluetoothPort, storagePort: StoragePort) {
        self.bluetoothPort = bluetoothPort
        self.storagePort = storagePort
        
        state = BehaviorRelay(value: .disabled)
        self.bluetoothPort.delegate = self
    }
    
    func startSyncing() -> Result<Void, Error> {
        switch state.value {
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
            state.accept(.disabled)
        case .enabled:
            state.accept(.enabled)
        case .peripheralConnected:
            state.accept(.discoveringSensorCharacteristics)
        case .characteristicDiscovered:
            state.accept(.syncingSensorData)
        }
    }
    
    func hasRead(heartRate: Int) {
        let record = HeartRateRecord(value: heartRate)
        storagePort.store(record: record) { [weak self] result in
            switch result {
            case .failure(let error):
                print("HeartRecord \(record) failed to be stored: \(error)")
            case .success:
                self?.heartRate.onNext(record)
            }
        }
    }
    
}
