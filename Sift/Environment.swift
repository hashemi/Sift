//
//  Environment.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-14.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Environment {
    private var values: [Atom: Value] = [:]
    
    func isBound(_ variable: Atom) -> Bool {
        return values.keys.contains(variable)
    }
    
    func get(_ variable: Atom) throws -> Value {
        guard let value = values[variable] else {
            throw LispError.unboundVar("Getting an unbound variable", variable)
        }
        return value
    }
    
    mutating func set(_ variable: Atom, value: Value) throws -> Value {
        guard let _ = values[variable] else {
            throw LispError.unboundVar("Getting an unbound variable", variable)
        }
        values[variable] = value
        return value
    }
    
    mutating func define(_ variable: Atom, value: Value) throws -> Value {
        values[variable] = value
        return value
    }
    
    mutating func bind(_ bindings: [Atom: Value]) {
        values.merge(bindings) { $1 }
    }
}
