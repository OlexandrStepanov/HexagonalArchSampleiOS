//
//  StoragePort.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/23/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation

protocol StoragePort {
    func store(record: HeartRateRecord, completion: @escaping (Result<Void, Error>) -> Void)
}
