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
    func eval() throws -> Value {
        switch self {
        case .string, .number, .boolean: return self
        case .list(let list):
            guard !list.isEmpty, case .atom(let name) = list[0] else { break }
            if name == Atom("quote") {
                return self
            }
            
            return try apply(name, try list[1...].map({ try $0.eval() }))
        default:
            break
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

func apply(_ funName: Atom, _ args: [Value]) throws -> Value {
    func wrap<T: ValueConvertible>(_ op: @escaping (T, T) -> T) -> (([Value]) throws -> (Value)) {
        return { (args: [Value]) throws -> Value in
            let valueArgs = try args.map(T.init)
            let result = valueArgs[1...].reduce(valueArgs.first!, op)
            return result.value
        }
    }
    
    let primitives: [Atom: ([Value]) throws -> (Value)] = [
        "+": wrap(+),
        "-": wrap(-),
        "*": wrap(*),
        "/": wrap(/),
        "mod": wrap(%),
        ]
    
    guard let fun = primitives[funName] else {
        throw LispError.notFunction("Unrecognized primitive function args", funName)
    }
    return try fun(args)
}
