//
//  Value.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-08.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Atom: Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    typealias StringLiteralType = String
    
    private let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    init(stringLiteral: Atom.StringLiteralType) {
        self.init(stringLiteral)
    }
    
    var hashValue: Int { return name.hashValue }
    
    static func ==(lhs: Atom, rhs: Atom) -> Bool {
        return lhs.name == rhs.name
    }
    
    var description: String {
        return name
    }
}

enum Value {
    case atom(Atom)
    case list([Value])
    indirect case dottedList([Value], Value)
    case number(Int)
    case string(String)
    case boolean(Bool)
    case primitiveFunction(([Value]) throws -> Value)
    case function(params: [Atom], varArg: Atom?, body: [Value], closure: Environment)
    
    var boolValue: Bool {
        if case let .boolean(bool) = self {
            return bool
        }
        return false
    }
}

extension Value: CustomStringConvertible {
    var description: String {
        switch self {
        case .string(let contents):
            return "\"" + contents + "\""
        case .atom(let name):
            return name.description
        case .number(let number):
            return number.description
        case .boolean(true):
            return "#t"
        case .boolean(false):
            return "#f"
        case .list(let contents):
            return "(" + contents.map { $0.description }.joined(separator: " ") + ")"
        case .dottedList(let head, let tail):
            return "(" + head.map { $0.description }.joined(separator: " ") + " . " + tail.description + ")"
        case .primitiveFunction(_):
            return "<primitive>"
        case .function(let params, let varArg, _, _):
            let varArgFragment: String
            switch varArg {
            case .none: varArgFragment = ""
            case .some(let arg): varArgFragment = " . " + arg.description
            }

            return "(lambda (" +
                params.map { $0.description }.joined(separator: " ") +
                varArgFragment +
                ") ...)"
        }
    }
}

extension Value {
    func eval(_ env: Environment) throws -> Value {
        switch self {
        case .string, .number, .boolean: return self
        case .atom(let id): return try env.get(id)
        case .list(let list):
            guard !list.isEmpty, case .atom(let name) = list[0] else { break }
            switch name {
            case "quote" where list.count == 2:
                return list[1]
                
            case "if" where list.count == 4:
                let (pred, conseq, alt) = (list[1], list[2], list[3])
                return try ((try pred.eval(env).boolValue) ? conseq : alt).eval(env)
                
            case "set!" where list.count == 3:
                guard case .atom(let variable) = list[1] else { break }
                return try env.set(variable, value: list[2])
                
            case "define" where list.count == 3:
                guard case .atom(let variable) = list[1] else { break }
                return try env.define(variable, value: list[2])
                
            default:
                let function = try list[0].eval(env)
                let args = try list[1...].map({ try $0.eval(env) })
                return try apply(function, args)
            }
        default: break
        }
        throw LispError.badSpecialForm("Unrecognized special form", self)
    }
}

protocol ValueConvertible {
    init(value: Value) throws
    var value: Value { get }
}

extension Int: ValueConvertible {
    init(value: Value) throws {
        switch value {
        case .number(let n): self = n
        default: throw LispError.typeMismatch("number", value)
        }
    }
    
    var value: Value {
        return .number(self)
    }
}

extension Bool: ValueConvertible {
    init(value: Value) throws {
        switch value {
        case .boolean(let b): self = b
        default: throw LispError.typeMismatch("boolean", value)
        }
    }
    
    var value: Value {
        return .boolean(self)
    }
}

extension String: ValueConvertible {
    init(value: Value) throws {
        switch value {
        case .string(let s): self = s
        default: throw LispError.typeMismatch("string", value)
        }
    }
    
    var value: Value {
        return .string(self)
    }
}

func apply(_ fun: Value, _ args: [Value]) throws -> Value {
    switch fun {
    case .primitiveFunction(let fun):
        return try fun(args)
        
    case .function(let params, let varArg, let body, let closure):
        switch varArg {
        case .none where args.count == params.count:
            closure.bind(Dictionary(zip(params, args)) { $1 })
        case .some(let varArgName) where args.count >= params.count:
            closure.bind(Dictionary(zip(params, args.prefix(params.count))) { $1 })
            let remainingArgs = Value.list(Array(args[params.count...]))
            closure.bind([varArgName: remainingArgs])
        default:
            throw LispError.numArgs(params.count, args)
        }
        
        var lastValue: Value = .list([])
        for v in body {
            lastValue = try v.eval(closure)
        }
        return lastValue
        
    default:
        fatalError("Interpreter error: attempted to apply a non-function.")
    }
}

extension Value: Equatable {
    static func ==(lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case let (.boolean(b1), .boolean(b2)):
            return b1 == b2
        case let (.number(n1), .number(n2)):
            return n1 == n2
        case let (.string(s1), .string(s2)):
            return s1 == s2
        case let (.atom(a1), .atom(a2)):
            return a1 == a2
        case let (.dottedList(l1, afterDot1), .dottedList(l2, afterDot2)):
            return l1 == l2 && afterDot1 == afterDot2
        case let (.list(l1), .list(l2)):
            return l1 == l2
        case (.boolean, _), (.number, _), (.string, _),
             (.atom, _), (.dottedList, _), (.list, _),
             (.function, _), (.primitiveFunction, _):
            return false
        }
    }
}
