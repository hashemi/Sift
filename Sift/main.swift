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

    init(_ message: String, _ value: Value = .null) {
        self.message = message
        self.value = value
    }
}

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

indirect enum Expr {
    case value(Value)
    case quote(Expr)
    case `if`(Expr, Expr, Expr)
    case begin([Expr])
    case set(Atom, Expr)
    case lambda(Value, Expr)
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

extension Expr {
    func evaluate(env: inout Environment) throws -> Value {
        switch self {
        case let .value(value):
            switch value {
            case let .atom(atom):
                return try env.lookup(atom)
            case .boolean, .number, .string, .char, .vector, .null, .pair, .function, .expr:
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
            return .null

        case let .set(symbol, value):
            try env.update(symbol, try value.evaluate(env: &env))
            return .null

        case let .lambda(variables, body):
            return .function(Lambda(variables: variables, body: body, env: env))

        case let .apply(funcExpr, argExprs):
            let evaluatedFuncExpr = try funcExpr.evaluate(env: &env)

            guard case let .function(function) = evaluatedFuncExpr
                else { throw Wrong("Not a function", evaluatedFuncExpr) }

            let arguments = Value(try argExprs.map { try $0.evaluate(env: &env) })

            return try function.apply(arguments)
        }
    }
}

Environment.defInitial("foo")
Environment.defInitial("bar")
Environment.defInitial("fib")
Environment.defInitial("fact")

Environment.defPrimitive("cons", 2) { args in
    return args[0] + args[1]
}

Environment.defPrimitive("car", 1) { args in
    return try args[0].car()
}

let test: Expr =
    .apply(
        .value(.atom("car")),
        [
            .apply(
                .value(.atom("cons")),
                [
                    .value(.number(1)),
                    .value(.number(2))
                ]
            )
        ]
    )

print(try test.evaluate(env: &.global))
