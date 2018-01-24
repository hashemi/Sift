//
//  Parser.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-11.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

struct Scanner {
    private let source: String
    private(set) var current: String.UnicodeScalarIndex
    
    func text(from start: String.UnicodeScalarIndex) -> String {
        return String(source.unicodeScalars[start..<current])
    }
    
    var isAtEnd: Bool {
        return current >= source.unicodeScalars.endIndex
    }
    
    var peek: UnicodeScalar {
        if isAtEnd { return "\0" }
        return source.unicodeScalars[current]
    }
    
    init(_ source: String) {
        self.source = source
        self.current = source.unicodeScalars.startIndex
    }
    
    @discardableResult mutating func advance() -> UnicodeScalar {
        let result = peek
        current = source.unicodeScalars.index(after: current)
        return result
    }
    
    mutating func match(_ expected: UnicodeScalar) -> Bool {
        if isAtEnd { return false }
        if peek != expected { return false }
        advance()
        return true
    }
    
    mutating func skip(while filter: (UnicodeScalar) -> Bool) {
        while !isAtEnd && filter(peek) { advance() }
    }
}

enum Token {
    case lParen
    case rParen
    case quote
    case dot
    case `true`
    case `false`
    
    case atom(String)
    case number(Int)
    case string(String)
    
    case eof
}

extension UnicodeScalar {
    var isSymbol: Bool {
        switch self {
        case "!", "$", "%", "&", "|", "*",
             "+", "-", "/", ":", "<", "=",
             "?", ">", "@", "^", "_", "~",
             "#": return true
        default: return false
        }
    }
    
    var isDigit: Bool {
        switch self {
        case "0"..."9": return true
        default: return false
        }
    }
    
    var isAlpha: Bool {
        switch self {
        case "a"..."z": return true
        case "A"..."Z": return true
        default: return false
        }
    }
    
    var isWhitespace: Bool {
        switch self {
        case " ", "\t", "\n", "\r": return true
        default: return false
        }
    }
}

struct Lexer {
    private var scanner: Scanner
    
    init(_ source: String) throws {
        scanner = Scanner(source)
    }
    
    mutating func advance() throws -> Token {
        scanner.skip { $0.isWhitespace }
        
        if scanner.isAtEnd { return .eof }
        
        let start = scanner.current
        let c = scanner.advance()
        
        switch c {
        case "(": return .lParen
        case ")": return .rParen
        case "'": return .quote
        case ".": return .dot
        
        case "\"":
            let stringContentStart = scanner.current
            scanner.skip { $0 != "\"" }
            let content = scanner.text(from: stringContentStart)
            guard scanner.match("\"") else {
                throw LispError.parsingError("Expected a closing '\"'")
            }
            return .string(content)
            
        case _ where c.isAlpha || c.isSymbol:
            scanner.skip { $0.isAlpha || $0.isDigit || $0.isSymbol }
            let name = scanner.text(from: start)
            switch name {
            case "#t": return .true
            case "#f": return .false
            default: return .atom(name)
            }
        
        case _ where c.isDigit:
            scanner.skip { $0.isDigit }
            let digits = scanner.text(from: start)
            return .number(Int(digits)!)
            
        default:
            throw LispError.parsingError("Unexpected character '\(c)'")
        }
    }
}

struct Parser {
    private var lexer: Lexer
    
    init(_ source: String) throws {
        self.lexer = try Lexer(source)
    }
    
    mutating func parse() throws -> Value? {
        switch try internalParse() {
        case .value(let v): return v
        case .token(.rParen):
            throw LispError.parsingError("Unexpected ')'")
        case .token(.dot):
            throw LispError.parsingError("Unexpected '.'")
        case .token(.eof):
            return nil
        case .token(_):
            fatalError("Parser error") // this should never happen
        }
    }
    
    private enum ValueOrToken {
        case value(Value)
        case token(Token)
    }
    
    private mutating func internalParse() throws -> ValueOrToken {
        let token = try lexer.advance()
        switch token {
        case let .atom(name):
            return .value(.atom(Atom(name)))
        case let .number(number):
            return .value(.number(number))
        case let .string(string):
            return .value(.string(string))
        case .lParen:
            return try .value(list())
        case .quote:
            guard let quotedValue = try parse() else {
                throw LispError.parsingError("Unexpected end of file after quote")
            }
            return .value(.list([.atom("quote"), quotedValue]))
        case .true:
            return .value(.boolean(true))
        case .false:
            return .value(.boolean(false))
        case .rParen, .dot, .eof:
            return .token(token)
        }
    }
    
    mutating func list() throws -> Value {
        var items: [Value] = []
        
        while true {
            switch try internalParse() {
            case .value(let v):
                items.append(v)
            
            case .token(.rParen):
                return .list(items)
            
            case .token(.dot):
                let afterDot = try internalParse()
                let rParen = try internalParse()
                
                if
                    case .value(let lastValue) = afterDot,
                    case .token(.rParen) = rParen {
                    return .dottedList(items, lastValue)
                }
                throw LispError.parsingError("Malformed dotted list")
            
            case .token(.eof):
                throw LispError.parsingError("Expected ')'")
            
            case .token(_):
                fatalError("Parser error")
            }
        }
    }
}
