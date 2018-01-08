# Sift

A Lisp implementation written in Swift, following Christian Queinnec's book [Lisp in Small Pieces](https://www.cambridge.org/core/books/lisp-in-small-pieces/66FD2BE3EDDDC68CA87D652C82CF849E).

## Journal

* 7 Jan 2017 — Near the end of Chapter 1 of the book. The book describes a meta-circular implementation using Lisp/Scheme as the host language. However, given that this a Swift implementation, a few pieces are missing and will need to be implemented. The code currently compiles. The next step is to write an expression and fill in the blanks necessary for it to be evaluated correctly. At this stage, expressions will be constructed in Swift code as we don't have a Lisp lexer and parser yet.