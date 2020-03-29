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
    @IBOutlet weak private var lastValue: UILabel!
    
    var presenter: HeartRatePresenter?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter?.delegate = self
    }

    func presenter(_ presenter: HeartRatePresenter, didUpdateState state: HeartRatePresenter.State) {
        switch state {
        case .notActive:
            stateLabel.text = "Bluetooth disabled"
            lastValue.text = nil
        case .searchingSensor:
            stateLabel.text = "Searching HRM..."
            lastValue.text = nil
        case .connected(let lastRecord):
            stateLabel.text = "Connected"
            if let lastRecord = lastRecord {
                lastValue.text = "\(lastRecord.value) BPM"
            } else {
                lastValue.text = nil
            }
        }
    }
    
    
    
}

