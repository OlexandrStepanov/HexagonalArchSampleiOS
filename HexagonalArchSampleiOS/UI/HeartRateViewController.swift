//
//  HeartRateViewController.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 1/31/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import UIKit

class HeartRateViewController: UIViewController, HeartRatePresenterDelegate {
    
    @IBOutlet weak private var stateLabel: UILabel!
    @IBOutlet weak private var bpmLabel: UILabel!
    @IBOutlet weak private var actionButton: UIButton!
    
    var presenter: HeartRatePresenter!
    
    static func build() -> HeartRateViewController {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? HeartRateViewController else {
            fatalError("Can't instantiate HeartRateViewController from Main.storyboard")
        }
        
        //  INFO: In fact, in real life project it's better to instantiate services separately in some kind of app coordinator or DI container
        let heartService = HeartRateService(bluetoothPort: BluetoothAdapter(), storagePort: StorageAdapter())
        let presenter = HeartRatePresenter(heartRateService: heartService)
        vc.presenter = presenter
        
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.delegate = self
    }
    
    @IBAction func actionButtonHanlder() {
        switch presenter.state {
        case .notActive:
            presenter.startSearch()
        case .searchingSensor, .connected:
            presenter.disconnect()
        }
    }

    func presenter(_ presenter: HeartRatePresenter, didUpdateState state: HeartRatePresenter.State) {
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

