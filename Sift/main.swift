//
//  main.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-07.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

var p = Parser("(+ 1 (- 3 1) 3 (* 2 2) (mod 11 6) (/ 12 2) 7 8 9 10)")
print(p.parse().eval)
