//
//  main.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-07.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

let expressions = [
    "(+ 1 (- 3 1) 3 (* 2 2) (mod 11 6) (/ 12 2) 7 8 9 10)",
    "(+ 2 \"two\")",
    "(< 2 3)",
    "(> 2 3)",
    "(>= 3 3)",
    "(string=? \"test\" \"test\")",
    "(string<? \"abc\" \"bba\")",
    "(if (> 2 3) \"no\" \"yes\")",
    "(if (= 3 3) (+ 2 3 (- 5 1)) \"unequal \")",
    "(car '(1 2 3))",
    "(cdr '(1 2))",
    "(car (cons 1 (cons 2 (cons 3 '()))))",
    "(cdr (cons 1 (cons 2 (cons 3 '()))))",
    "(eqv? 1 3)",
    "(eqv? 'atom 'atom)",
]

func evalPrint(_ expr: String) throws {
    do {
        var p = try Parser(expr)
        let parsed = try p.parse()
        print(try parsed.eval().description)
    } catch let error as LispError {
        print(error.description)
    }
}

for expr in expressions {
    print("> \(expr)")
    try evalPrint(expr)
}

while true {
    print("> ", terminator: "")
    let expr = readLine() ?? ""
    if expr == "quit" { break }
    try evalPrint(expr)
}
