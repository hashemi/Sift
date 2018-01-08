//
//  main.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-07.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Wrong: Error {
    let message: String
    let value: Value

    init(_ message: String, _ value: Value = .nil) {
        self.message = message
        self.value = value
    }
}

struct Atom: Hashable {
    private let name: String

    init(_ name: String) {
        self.name = name
    }

    var hashValue: Int { return name.hashValue }

    static func == (lhs: Atom, rhs: Atom) -> Bool {
        return lhs.name == rhs.name
    }
}

struct Vector { }

struct Function {
    let variables: List<Atom>
    let body: Expr
    let env: Environment

    func apply(_ arguments: [Value]) throws -> Value {
        var newEnv = try env.extend(variables, arguments)
        return try body.evaluate(env: &newEnv)
    }
}

enum List<T> {
    case plain([T])
    case dotted([T], T)

    static var empty: List { return .plain([]) }
}

enum Value {
    case atom(Atom)
    case number(Int)
    case string(String)
    case char(UnicodeScalar)
    case boolean(Bool)
    case vector(Vector)
    indirect case list(List<Value>)
    case function(Function)
    case expr(Expr)

    static var `nil`: Value { return .list(.empty) }

    var boolValue: Bool {
        switch self {
        case .boolean(let bool):
            return bool
        case .atom, .number, .string,
             .char, .vector, .list,
             .function, .expr:
            return true
        }
    }
}

indirect enum Expr {
    case value(Value)
    case quote(Expr)
    case `if`(Expr, Expr, Expr)
    case begin([Expr])
    case set(Atom, Expr)
    case lambda(List<Atom>, Expr)
    case apply(Expr, [Expr])
}

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

    func extend(_ variables: List<Atom>, _ values: [Value]) throws -> Environment {
        switch variables {
        case let .plain(list):
            if list.count < values.count {
                throw Wrong("Too many values")
            }

            if list.count > values.count {
                throw Wrong("Too less values")
            }

            let newDict = dict.merging(zip(list, values)) { (_, new) in new }
            return Environment(dict: newDict)

        case let .dotted(list, dot):
            if list.count > values.count {
                throw Wrong("Too less values")
            }

            let mapped = zip(list, values[..<list.count])
            var newDict = dict.merging(mapped) { (_, new) in new }

            let remainder = Array(values[list.count...])
            newDict[dot] = .list(.plain(remainder))
            return Environment(dict: newDict)
        }
    }
}

extension Expr {
    func evaluate(env: inout Environment) throws -> Value {
        switch self {
        case let .value(value):
            switch value {
            case let .atom(atom):
                return try env.lookup(atom)
            case .boolean, .number, .string, .char, .vector, .list, .function, .expr:
                return value
            }

        case let .quote(expr):
            return .expr(expr)

        case let .if(cond, then, otherwise):
            return
                try (cond.evaluate(env: &env).boolValue ? then : otherwise)
                    .evaluate(env: &env)

        case let .begin(exprs):
            for expr in exprs {
                _ = try expr.evaluate(env: &env)
            }
            return .nil

        case let .set(symbol, value):
            try env.update(symbol, try value.evaluate(env: &env))
            return .nil

        case let .lambda(variables, body):
            return .function(Function(variables: variables, body: body, env: env))

        case let .apply(funcExpr, argExprs):
            let evaluatedFuncExpr = try funcExpr.evaluate(env: &env)

            guard case let .function(function) = evaluatedFuncExpr
                else { throw Wrong("Not a function", evaluatedFuncExpr) }

            let arguments = try argExprs.map { try $0.evaluate(env: &env) }

            return try function.apply(arguments)
        }
    }
}
