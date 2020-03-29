//
//  HeartRatePresenter.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/25/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation

protocol HeartRatePresenterDelegate: class {
    func presenter(_ presenter: HeartRatePresenter, didUpdateState state: HeartRatePresenter.State)
}

class HeartRatePresenter: HeartRateServiceDelegate {
    
    enum State {
        case notActive
        case searchingSensor
        case connected(lastRecord: HeartRateRecord?)
    }
    
    var state: State {
        didSet {
            delegate?.presenter(self, didUpdateState: state)
        }
    }
    
    weak var delegate: HeartRatePresenterDelegate? {
        didSet {
            delegate?.presenter(self, didUpdateState: state)
        }
    }
    
    private let heartRateService: HeartRateServiceProtocol
    
    init(heartRateService: HeartRateServiceProtocol) {
        self.heartRateService = heartRateService
        
        state = .notActive
    }
    
    // MARK: HeartRatePresenterProtocol
    
    func startSearch() {
        switch heartRateService.startSyncing() {
        case .failure(let error):
            print("Start searching sensor failed: \(error)")
        case .success:
            break
        }
    }
    
    func disconnect() {
        heartRateService.stopSyncing()
    }
    
    // MARK: HeartRateServiceDelegate
    
    func stateDidChange(to newState: HeartRateService.State) {
        switch newState {
        case .disabled:
            state = .notActive
        case .enabled, .discoveringSensorCharacteristics, .searchingSensor:
            state = .searchingSensor
        case .syncingSensorData:
            state = .connected(lastRecord: nil)
        }
    }
    
    func hasRecorded(record: HeartRateRecord) {
        switch heartRateService.state {
        case .disabled, .enabled, .discoveringSensorCharacteristics, .searchingSensor:
            break
        case .syncingSensorData:
            state = .connected(lastRecord: record)
        }
    }
}
