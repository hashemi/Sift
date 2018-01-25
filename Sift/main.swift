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
    "(define (f x y) (+ x y))",
    "(f 1 2)",
    "(f 1 2 3)",
    "(define (factorial x) (if (= x 1) 1 (* x (factorial (- x 1)))))",
    "(factorial 10)",
    "(define (counter inc) (lambda (x) (set! inc (+ x inc)) inc))",
    "(define my-count (counter 5))",
    "(my-count 3)",
    "(my-count 6)",
    
    "(define filename \"/Users/ahmadh/test.rkt\")",
    "(define file (open-input-file filename))",
    "(read file)",
    "(close-input-port file)",
    
    "(define wfilename \"/Users/ahmadh/test.txt\")",
    "(define wf (open-output-file wfilename))",
    "(write \"This is a test\" wf)",
    "(close-output-port wf)",
    
    "(read-contents \"/Users/ahmadh/test.txt\")",
]

var env = Environment()
env.bind(primitives.mapValues { Value.primitiveFunction($0) })

func evalPrint(_ expr: String) throws {
    do {
        var p = try Parser(expr)
        let parsed = try p.parse()
        print(try parsed?.eval(env).description ?? "")
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
