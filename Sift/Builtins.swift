//
//  Builtins.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-11.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

func addBuiltins() {
    Environment.defInitial("foo")
    Environment.defInitial("bar")
    Environment.defInitial("fib")
    Environment.defInitial("fact")
    
    Environment.defPrimitive("cons", 2) { args in
        var iter = args.makeIterator()
        return .pair(iter.next()!, iter.next()!)
    }
    
    Environment.defPrimitive("car", 1) { args in
        var iter = args.makeIterator()
        guard case let .pair(car, _) = iter.next()! else {
            throw Wrong("car: expected pair")
        }
        return car
    }
}
