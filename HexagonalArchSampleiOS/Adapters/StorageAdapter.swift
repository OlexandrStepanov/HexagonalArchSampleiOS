//
//  StorageAdapter.swift
//  HexagonalArchSampleiOS
//
//  Created by Oleksandr Stepanov on 3/23/20.
//  Copyright © 2020 Oleksandr Stepanov. All rights reserved.
//

import Foundation
import Firebase


class StorageAdapter: StoragePort {
    
    let db = Firestore.firestore()
    
    init() {
    }
    
    func store(record: HeartRateRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("HeartRateRecord").addDocument(data: ["value" : record.value]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
}
