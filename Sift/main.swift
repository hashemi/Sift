//
//  main.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-07.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

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
