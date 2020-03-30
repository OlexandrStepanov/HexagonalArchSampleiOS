//
//  HeartRateViewModel.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/30/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay


protocol HeartRateViewModelProtocol {
    var state: BehaviorRelay<HeartRateViewModel.State> { get }
    
    func startSearch()
    func disconnect()
}

class HeartRateViewModel: HeartRateViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    
    enum State {
        case notActive
        case searchingSensor
        case connected(lastRecord: HeartRateRecord?)
    }
    
    let state: BehaviorRelay<HeartRateViewModel.State>
    private let heartRateService: HeartRateServiceProtocol
    
    init(heartRateService: HeartRateServiceProtocol) {
        self.heartRateService = heartRateService
        state = BehaviorRelay(value: .notActive)
        
        heartRateService.state.subscribe(onNext: { [weak self] state in
            self?.handle(newState: state)
        }).disposed(by: disposeBag)
        
        heartRateService.heartRate.subscribe(onNext: { [weak self] record in
            self?.handle(record: record)
        }).disposed(by: disposeBag)
    }
    
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
    
    // MARK: Private
    
    private func handle(newState: HeartRateService.State) {
        switch newState {
        case .disabled:
            state.accept(.notActive)
        case .enabled, .discoveringSensorCharacteristics, .searchingSensor:
            state.accept(.searchingSensor)
        case .syncingSensorData:
            state.accept(.connected(lastRecord: nil))
        }
    }
    
    private func handle(record: HeartRateRecord) {
        switch heartRateService.state.value {
        case .disabled, .enabled, .discoveringSensorCharacteristics, .searchingSensor:
            break
        case .syncingSensorData:
            state.accept(.connected(lastRecord: record)) 
        }
    }
}
