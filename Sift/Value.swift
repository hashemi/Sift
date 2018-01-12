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
