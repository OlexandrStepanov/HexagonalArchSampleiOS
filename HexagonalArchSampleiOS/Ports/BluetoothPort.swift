//
//  BluetoothPort.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/23/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation

protocol BluetoothPortDelegate: class {
    func stateDidChange(to newState: BluetoothPortState)
    func hasRead(heartRate: Int)
}

protocol BluetoothPort {
    var state: BluetoothPortState { get }
    var delegate: BluetoothPortDelegate? { get set }
    
    func startScanning()
    func stopScanning()
}

enum BluetoothPortState {
    case disabled(reason: String)
    case enabled
    case peripheralConnected
    case characteristicDiscovered
}

