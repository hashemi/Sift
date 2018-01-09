//
//  Value.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-08.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Atom: Hashable, ExpressibleByStringLiteral {
    typealias StringLiteralType = String
    
    private let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    init(stringLiteral: Atom.StringLiteralType) {
        self.init(stringLiteral)
    }
    
    var hashValue: Int { return name.hashValue }
    
    static func == (lhs: Atom, rhs: Atom) -> Bool {
        return lhs.name == rhs.name
    }
}

struct Vector { }

protocol Function {
    func apply(_ arguments: Value) throws -> Value
}

struct Lambda: Function {
    let variables: Value
    let body: Expr
    let env: Environment
    
    func apply(_ arguments: Value) throws -> Value {
        var newEnv = try env.extend(variables, arguments)
        return try body.evaluate(env: &newEnv)
    }
}

struct NativeFunction: Function {
    typealias Body = ([Value]) throws -> (Value)
    
    let name: Atom
    let arity: Int
    let body: Body
    
    init(_ name: Atom, _ arity: Int, body: @escaping Body) {
        self.name = name
        self.arity = arity
        self.body = body
    }
    
    func apply(_ arguments: Value) throws -> Value {
        let argumentArray = arguments.asArray
        guard argumentArray.count == arity else {
            throw Wrong("Incorrect arity", .atom(name) + arguments)
        }
        return try body(argumentArray)
    }
}

enum Value {
    case atom(Atom)
    case number(Int)
    case string(String)
    case char(UnicodeScalar)
    case boolean(Bool)
    case vector(Vector)
    case null
    indirect case pair(Value, Value)
    case function(Function)
    case expr(Expr)
    
    var boolValue: Bool {
        switch self {
        case .boolean(let bool):
            return bool
        case .atom, .number, .string,
             .char, .vector, .null, .pair,
             .function, .expr:
            return true
        }
    }
    
    // cons
    static func + (lhs: Value, rhs: Value) -> Value {
        return .pair(lhs, rhs)
    }
    
    // Swift Array to LISP list
    init(_ values: [Value]) {
        self = values.reversed().reduce(Value.null) { list, value in
            return value + list
        }
    }
    
    // LISP list to Swift Array
    var asArray: [Value] {
        var values: [Value] = []
        var current = self
        while true {
            switch current {
            case let .pair(head, tail):
                values.append(head)
                current = tail
            case .null:
                return values
            default:
                fatalError("Attempted to convert a non-LISP list into a Swift array")
            }
        }
    }
    
    func car() throws -> Value {
        guard case let .pair(car, _) = self else {
            throw Wrong("car: expected pair")
        }
        return car
    }
}
