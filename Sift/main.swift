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
]

for expr in expressions {
    do {
        var p = try Parser(expr)
        print(try p.parse().eval().description)
    } catch let error as LispError {
        print(error.description)
    }
}
