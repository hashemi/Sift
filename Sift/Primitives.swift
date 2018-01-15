//
//  Primitives.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-15.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

private func reducer<T: ValueConvertible>(_ type: T.Type, _ op: @escaping (T, T) -> T) -> (([Value]) throws -> (Value)) {
    return { (args: [Value]) throws -> Value in
        let valueArgs = try args.map(T.init)
        let result = valueArgs[1...].reduce(valueArgs.first!, op)
        return result.value
    }
}

private func wrap<T: ValueConvertible, U: ValueConvertible>(_ type: T.Type, _ op: @escaping (T, T) -> U) -> (([Value]) throws -> (Value)) {
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
