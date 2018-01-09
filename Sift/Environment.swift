//
//  Environment.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-08.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Environment {
    private var dict: [Atom: Value]
    
    private init(dict: [Atom: Value]) {
        self.dict = dict
    }
    
    static var initial: Environment {
        return Environment(dict: [:])
    }
    
    static var global: Environment = {
        var env = Environment.initial
        return env
    }()
    
    static func defInitial(_ name: Atom, _ value: Value = .atom("void")) {
        Environment.global.dict[name] = value
    }
    
    static func defPrimitive(_ name: Atom, _ arity: Int, body: @escaping NativeFunction.Body) {
        Environment.global.dict[name] = .function(NativeFunction(name, arity, body: body))
    }
    
    func lookup(_ atom: Atom) throws -> Value {
        guard let value = dict[atom] else {
            throw Wrong("No such binding", .atom(atom))
        }
        return value
    }
    
    mutating func update(_ atom: Atom, _ value: Value) throws {
        guard dict[atom] != nil else {
            throw Wrong("No such binding", .atom(atom))
        }
        dict[atom] = value
    }
    
    func extend(_ variables: Value, _ values: Value) throws -> Environment {
        switch (variables, values) {
        case let (.pair(.atom(name), varTail), .pair(value, valTail)):
            var newDict = dict
            newDict[name] = value
            return try Environment(dict: newDict).extend(varTail, valTail)
            
        case (.pair, _):
            throw Wrong("Too less values")
            
        case (.null, .null):
            return self
            
        case (.null, _):
            throw Wrong("Too much values")
            
        case let (.atom(name), _):
            var newDict = dict
            newDict[name] = values
            return Environment(dict: newDict)
        }
    }
}
