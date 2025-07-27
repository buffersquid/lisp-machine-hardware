# LISP Machine (cons all the way down)

# LISP Machine Hardware Implementation Plan

## Phase 1: Data Representation and Memory

### Types

Every type is at least 2 words in size. One word for the header, and the rest for data.
Some types need more data than others.

#### Atom

Includes:
- Number
- Symbol
- String
- Functions

##### Number
```
[type_number]
[data]
```
##### Symbol
```
[type_symbol]
[pointer to obj]
```

```
[type_symbol_object]
[pointer to name (string)]
[pointer to value (anything)]
[pointer to function_cell (function)]
[pointer to property list (cons list)] # Ignoring for first version
```

Having 2 pointers for a symbol (one for value and one for function) allows for "easier"
programming, and shouldn't cause clashes with naming conventions. This is actually a LISP-1
vs. LISP-2 debate, where LISP-1 has 1 namespace and LISP-2 has 2. The best arguments for
using a LISP-2 system are:
- It's what actual lisp machines did (when in Rome I guess)
- It allows for symbols to be both "nouns" and "verbs". Like you can say:
```
(define list '(4 5 6))
(list 1 2 3 list)
```
And the system will know that you mean run the function `list` on arguments 1, 2, 3, and list
(which resolves to 4, 5, and 6).

If I will continue down the LISP-2 path, I'm not sure. Scheme uses LISP-1, and I'm a sucker for
scheme...

##### String
For strings, I am still pondering if to use a dynamic size, where we just look for `\0`,
or to store the length in the header and cap the size of the string to some number. Since
we have small word size, I'm tempted by dynamic, since header space is limited.
```
[type_string]
[char0, char1]
[char2, char3]
[...]
[charN, \0]
```

##### Functions
```
[type_function]
[pointer to parameter list (cons list)]
[pointer to body expression (cons list)]
[closure env pointer (cons list)] # Probably ignoring this for now
```

###### Primitives
```
[type_function - subtype_primitive]
[primitive ID] # For example, ADD = 0, SUB = 1, CAR = 2, CDR = 3, etc
[nil] # No body for primitives
[nil] # No closure
```

###### Lambda
```
[type_function]
[pointer to parameter list (cons list)]
[pointer to body expression (cons list)]
[nil] # No captured lexical env for simple lambda
```
Example:
```
0x10 = symbol 'x'
0x11 = symbol 'y'
0x20 = cons(x, cons(y, NIL)) = param list
0x30 = cons('+', cons('x', cons('y', NIL))) = body

[0x40] = [type_function | subtype_lambda]  ; e.g. 0x01 | 1 = lambda
[0x41] = 0x20   ; → param list: (x y)
[0x42] = 0x30   ; → body: (+ x y)
[0x43] = NIL    ; → no captured environment
```
###### Closure (lambda with lexical env)
```
[type_function]
[pointer to parameter list (cons list)]
[pointer to body expression (cons list)]
[pointer to captured env]
```
Example:
```lisp
(define make-adder
  (lambda (n)
    (lambda (x) (+ x n))))
(define add5 (make-adder 5))
```

This creates a closure with:
- Param: `(x)`
- Body: `(+ x n)`
- Env: `n = 5`

```
0x10 = symbol 'x'
0x11 = symbol 'n'
0x20 = cons(x, NIL) = param list
0x30 = cons('+', cons('x', cons('n', NIL))) = body
0x51 = cons(cons('n', 5), NIL)

[0x40] = [type_function | subtype_closure]
[0x41] = 0x20   ; → param list: (x)
[0x42] = 0x30   ; → body: (+ x n)
[0x43] = 0x51   ; → pointer to captures env: ((n . 5))

```

#### Cons
```
[type_cons]
[pointer to car (anything)]
[pointer to cdr (anything)]
```

---

## Contribution:
[Style Guide for System Verilog](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)
