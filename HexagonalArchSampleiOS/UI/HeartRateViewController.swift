//
//  HeartRateViewController.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 1/31/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class HeartRateViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak private var stateLabel: UILabel!
    @IBOutlet weak private var bpmLabel: UILabel!
    @IBOutlet weak private var actionButton: UIButton!
    
    var viewModel: HeartRateViewModel!
    
    static func build() -> HeartRateViewController {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? HeartRateViewController else {
            fatalError("Can't instantiate HeartRateViewController from Main.storyboard")
        }
        
        //  INFO: In fact, in real life project it's better to instantiate services separately in some kind of app coordinator or DI container
        let heartService = HeartRateService(bluetoothPort: BluetoothAdapter(), storagePort: StorageAdapter())
        let vm = HeartRateViewModel(heartRateService: heartService)
        vc.viewModel = vm
        
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.handleMainAction()
        }).disposed(by: disposeBag)
        
        viewModel.state.subscribe(onNext: { [weak self] state in
            self?.handle(state: state)
        }).disposed(by: disposeBag)
    }
    
    private func handleMainAction() {
        switch viewModel.state.value {
        case .notActive:
            viewModel.startSearch()
        case .searchingSensor, .connected:
            viewModel.disconnect()
        }
    }

    private func handle(state: HeartRateViewModel.State) {
        switch state {
        case .notActive:
            stateLabel.text = "Bluetooth disabled"
            bpmLabel.text = nil
            actionButton.setTitle("Start search", for: .normal)
        case .searchingSensor:
            stateLabel.text = "Searching HRM..."
            bpmLabel.text = nil
            actionButton.setTitle("Stop search", for: .normal)
        case .connected(let lastRecord):
            stateLabel.text = "Connected"
            if let lastRecord = lastRecord {
                bpmLabel.text = "\(lastRecord.value) BPM"
            } else {
                bpmLabel.text = nil
            }
            actionButton.setTitle("Disconnect", for: .normal)
        }
    }
}

