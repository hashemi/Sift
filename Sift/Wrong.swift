//
//  Wrong.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-08.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Wrong: Error {
    let message: String
    let value: Value
    
    init(_ message: String, _ value: Value = .null) {
        self.message = message
        self.value = value
    }
}


