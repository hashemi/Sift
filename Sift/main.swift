//
//  main.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-07.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

let test1: Expr =
    .apply(
        .value(.atom("car")),
        .list([
            .apply(
                .value(.atom("cons")),
                .list([
                    .value(.number(1)),
                    .value(.number(2))
                ])
            )
        ])
    )

let test2: Expr =
    .apply(
        .value(.atom("eq?")),
        .list([
            .apply(
                .value(.atom("+")),
                .list([
                    .value(.number(1)),
                    .value(.number(1))
                ])
            ),
            .value(.number(2))
        ])
    )

addBuiltins()
print(try test1.evaluate(env: &.global))
print(try test2.evaluate(env: &.global))
