//
//  LispError.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-13.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

enum LispError: Error, CustomStringConvertible {
    case numArgs(Int, [Value])
    case typeMismatch(String, Value)
    case parsingError(String)
    case badSpecialForm(String, Value)
    case notFunction(String, Atom)
    case unboundVar(String, Atom)
    case other(String)
    
    var description: String {
        switch self {
        case let .numArgs(expected, found):
            return "Expected \(expected) args: found values "
                + found.map({ $0.description }).joined(separator: " ")
        case let .typeMismatch(expected, found):
            return "Invalid type: expected \(expected), found \(found.description)"
        case let .parsingError(message):
            return "Parsing error: \(message)"
        case let .badSpecialForm(message, form):
            return "\(message): \(form)"
        case let .notFunction(message, fun):
            return "\(message): \(fun.description)"
        case let .unboundVar(message, varName):
            return "\(message): \(varName)"
        case let .other(message):
            return message
        }
    }
}
