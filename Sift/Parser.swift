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
    private var _peek: Token?
    var peek: Token { return self._peek! }
    
    init(_ source: String) throws {
        scanner = Scanner(source)
        _peek = try lex()
    }
    
    mutating func advance() throws -> Token {
        let ret = _peek
        _peek = try lex()
        return ret!
    }
    
    private mutating func lex() throws -> Token {
        if scanner.isAtEnd { return .eof }
        
        scanner.skip { $0.isWhitespace }
        
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
                throw ParserError("Expected a closing '\"'")
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
            throw ParserError("Unexpected character '\(c)'")
        }
    }
}

struct Parser {
    private var lexer: Lexer
    
    init(_ source: String) throws {
        self.lexer = try Lexer(source)
    }
    
    mutating func parse() throws -> Value {
        let token = try lexer.advance()
        switch token {
        case let .atom(name):
            return .atom(Atom(name))
        case let .number(number):
            return .number(number)
        case let .string(string):
            return .string(string)
        case .lParen:
            return try list()
        case .quote:
            return .list([.atom("quote"), try parse()])
        case .true: return .boolean(true)
        case .false: return .boolean(false)
        case .rParen, .dot, .eof:
            throw ParserError("Unexpected token or end of file")
        }
    }
    
    mutating func list() throws -> Value {
        var items: [Value] = []
        
        while true {
            if case .eof = lexer.peek { break }
            if case .dot = lexer.peek { break }
            if case .rParen = lexer.peek { break }
            items.append(try parse())
        }
        
        switch lexer.peek {
        case .dot:
            _ = try lexer.advance() // skip over '.'
            let lastItem = try parse()
            if case .rParen = try lexer.advance() {
                return .dottedList(items, lastItem)
            }
        case .rParen:
            _ = try lexer.advance() // skip over ')'
            return .list(items)
        default: break
        }
        
        throw ParserError("Expected ')'")
    }
}
