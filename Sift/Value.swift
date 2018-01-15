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
        }
    }
}

extension Value {
    func eval(_ env: inout Environment) throws -> Value {
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
                return try ((try pred.eval(&env).boolValue) ? conseq : alt).eval(&env)
                
            case "set!" where list.count == 3:
                guard case .atom(let variable) = list[1] else { break }
                return try env.set(variable, value: list[2])
                
            case "define" where list.count == 3:
                guard case .atom(let variable) = list[1] else { break }
                return try env.define(variable, value: list[2])
                
            default:
                return try apply(name, try list[1...].map({ try $0.eval(&env) }))
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

func apply(_ funName: Atom, _ args: [Value]) throws -> Value {
    func reducer<T: ValueConvertible>(_ type: T.Type, _ op: @escaping (T, T) -> T) -> (([Value]) throws -> (Value)) {
        return { (args: [Value]) throws -> Value in
            let valueArgs = try args.map(T.init)
            let result = valueArgs[1...].reduce(valueArgs.first!, op)
            return result.value
        }
    }
    
    func wrap<T: ValueConvertible, U: ValueConvertible>(_ type: T.Type, _ op: @escaping (T, T) -> U) -> (([Value]) throws -> (Value)) {
        return { (args: [Value]) throws -> Value in
            guard args.count == 2 else { throw LispError.numArgs(2, args) }
            let valueArgs = try args.map(T.init)
            return op(valueArgs[0], valueArgs[1]).value
        }
    }
    
    let primitives: [Atom: ([Value]) throws -> (Value)] = [
        "+": reducer(Int.self, +),
        "-": reducer(Int.self, -),
        "*": reducer(Int.self, *),
        "/": reducer(Int.self, /),
        "mod": reducer(Int.self, %),
        
        "=": wrap(Int.self, ==),
        "<": wrap(Int.self, <),
        ">": wrap(Int.self, >),
        "/=": wrap(Int.self, !=),
        ">=": wrap(Int.self, >=),
        "<=": wrap(Int.self, <=),
        
        "&&": wrap(Bool.self, { (l: Bool, r: Bool) -> Bool in l && r }),
        "||": wrap(Bool.self, { (l: Bool, r: Bool) -> Bool in l || r }),
        
        "string=?": wrap(String.self, ==),
        "string<?": wrap(String.self, <),
        "string>?": wrap(String.self, >),
        "string<=?": wrap(String.self, <=),
        "string>=?": wrap(String.self, >=),
        
        "car": { (args: [Value]) -> Value in
            guard args.count == 1 else { throw LispError.numArgs(1, args) }
            switch args[0] {
            case .list(let list) where list.count >= 1:
                return list[0]
            case .dottedList(let list, _) where list.count >= 1:
                return list[0]
            default:
                throw LispError.typeMismatch("pair", args[0])
            }
        },
        
        "cdr": { (args: [Value]) -> Value in
            guard args.count == 1 else { throw LispError.numArgs(1, args) }
            switch args[0] {
            case .list(let list) where list.count >= 2:
                return .list(Array(list[1...]))
            case .dottedList(let list, let afterDot) where list.count >= 2:
                return .dottedList(Array(list[1...]), afterDot)
            case .dottedList(_, let afterDot):
                return afterDot
            default:
                throw LispError.typeMismatch("pair", args[0])
            }
        },
        
        "cons": { (args: [Value]) -> Value in
            guard args.count == 2 else { throw LispError.numArgs(2, args) }
            switch (args[0], args[1]) {
            case (_, .list(let tail)):
                return .list([args[0]] + tail)
            case (_, .dottedList(let tail, let afterDot)):
                return .dottedList([args[0]] + tail, afterDot)
            default:
                return .dottedList([args[0]], args[1])
            }
        },
        
        "eq?": { (args: [Value]) -> Value in
            guard args.count == 2 else { throw LispError.numArgs(2, args) }
            return .boolean(args[0] == args[1])
        },
        
        "eqv?": { (args: [Value]) -> Value in
            guard args.count == 2 else { throw LispError.numArgs(2, args) }
            return .boolean(args[0] == args[1])
        },
        ]
    
    guard let fun = primitives[funName] else {
        throw LispError.notFunction("Unrecognized primitive function args", funName)
    }
    return try fun(args)
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
             (.atom, _), (.dottedList, _), (.list, _):
            return false
        }
    }
}
