# Sift

A Lisp implementation written in Swift, following Christian Queinnec's book [Lisp in Small Pieces](https://www.cambridge.org/core/books/lisp-in-small-pieces/66FD2BE3EDDDC68CA87D652C82CF849E).

## Journal

* 7 Jan 2018 — Near the end of Chapter 1 of the book. The book describes a meta-circular implementation using Lisp/Scheme as the host language. However, given that this a Swift implementation, a few pieces are missing and will need to be implemented. The code currently compiles. The next step is to write an expression and fill in the blanks necessary for it to be evaluated correctly. At this stage, expressions will be constructed in Swift code as we don't have a Lisp lexer and parser yet.

* 8 Jan 2018 — Evaluated the first expression! Swift Arrays cannot capture the nuances of Lisp lists. I changed the `Value` data structure to align better with Lisp's way of doing things and added a few helper functions to convert to and from Swift Array. This may be worth a revisit in the future with an eye towards performance. Next, I will need to look into the mutability story to correctly implement `set-cdr!`.