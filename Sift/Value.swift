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

struct Vector: Equatable {
    static func ==(lhs: Vector, rhs: Vector) -> Bool {
        return false
    }
}

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
        let argsArray = Array(arguments)
        guard argsArray.count == arity else {
            throw Wrong("Incorrect arity", .pair(.atom(name), arguments))
        }
        return try body(argsArray)
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
}

extension Value: Equatable {
    static func ==(lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case let (.atom(lhs), .atom(rhs)):
            return lhs == rhs
        case let (.number(lhs), .number(rhs)):
            return lhs == rhs
        case let (.string(lhs), .string(rhs)):
            return lhs == rhs
        case let (.char(lhs), .char(rhs)):
            return lhs == rhs
        case let (.boolean(lhs), .boolean(rhs)):
            return lhs == rhs
        case let (.vector(lhs), .vector(rhs)):
            return lhs == rhs
        case (.null, .null):
            return true
        case let (.pair(lhs1, lhs2), .pair(rhs1, rhs2)):
            return lhs1 == rhs1 && lhs2 == rhs2
        case (.atom, _), (.number, _), (.string, _), (.char, _),
             (.boolean, _), (.vector, _), (.null, _), (.pair, _),
             (.function, _), (.expr, _):
            return false
        }
    }
}
    
extension Value: Sequence {
    func makeIterator() -> ValueIterator {
        return ValueIterator(self)
    }
    
    struct ValueIterator: IteratorProtocol {
        var value: Value
        
        init(_ value: Value) {
            self.value = value
        }
        
        mutating func next() -> Value? {
            switch value {
            case let .pair(head, tail):
                self.value = tail
                return head
            case .null:
                return nil
            default:
                fatalError("Attempted to convert a non-LISP list into a Swift array")
            }
        }
    }
}
