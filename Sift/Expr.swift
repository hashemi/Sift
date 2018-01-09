//
//  Expr.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-08.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

indirect enum Expr {
    case value(Value)
    case quote(Expr)
    case `if`(Expr, Expr, Expr)
    case begin([Expr])
    case set(Atom, Expr)
    case lambda(Value, Expr)
    case apply(Expr, [Expr])
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
