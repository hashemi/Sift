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
        return .pair(args[0], args[1])
    }

    Environment.defPrimitive("car", 1) { args in
        guard case let .pair(car, _) = args[0] else {
            throw Wrong("car: expected pair")
        }
        return car
    }
}
