//
//  main.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-07.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

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

addBuiltins()
print(try test.evaluate(env: &.global))
