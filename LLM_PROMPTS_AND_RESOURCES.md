# LLM Prompts and Resources

**Name:** Cole Hanson  
**Assignment:** Program 2 - Scanner and Parser  
**AI Tool Used:** Claude (Anthropic)  

---

## Resources Used

1. **Course Materials:**
   - Grammar specification provided in assignment handout
   - Lecture notes on recursive descent parsing
   - Racket documentation: https://docs.racket-lang.org/

2. **AI Assistance:**
   - Claude AI (Anthropic) - Used for code generation and debugging
   - Consulted for implementing lexer, parser functions, and bug fixes

---

## LLM Interaction Log

### Prompt 1: Initial Token and Node Structures
**Me:**
> hey can you help me set up the basic structures for my parser? i need a token structure that holds the type, value, and line number. also need a node structure for the parse tree

**AI Response:**
```racket
;; Token structure: (token-type value line-number)
(struct token (type value line) #:transparent)

;; Parse tree node structure
(struct node (type children) #:transparent)
```

---

### Prompt 2: Lexer Setup
**Me:**
> ok now i need to build a lexer that tokenizes the input. it needs to handle keywords like if, then, else, begin, end, while, read, print. also need operators like :=, +, -, *, /, =, >, <, >=, <=, <>. and it should handle comments like /* */ that can be multiline. numbers can be ints or floats with optional signs. identifiers start with a letter and can have letters, digits, hyphens, or underscores

**AI Response:**
```racket
;; Check if character is whitespace (excluding newline)
(define (whitespace? ch)
  (member ch '(#\space #\tab #\return)))

;; Check if character is alphabetic
(define (alpha? ch)
  (or (char<=? #\a ch #\z)
      (char<=? #\A ch #\Z)))

;; Check if character is alphanumeric
(define (alphanumeric? ch)
  (or (alpha? ch)
      (char-numeric? ch)))

;; Check if character is digit
(define (digit? ch)
  (char-numeric? ch))

;; Check if character is nonzero digit
(define (nonzero? ch)
  (member ch '(#\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)))

;; Keywords in the language
(define keywords
  '("if" "then" "else" "begin" "end" "while" "read" "print"))

;; Tokenize the input string
(define (tokenize input)
  ;; [Full tokenize implementation with all helper functions]
  ;; [See AI_GENERATED_CODE.md for complete code]
  )
```

---

### Prompt 3: Parser Helper Functions
**Me:**
> now i need the parser helper functions. stuff like getting the current token, advancing to the next token, checking if a token matches a certain type, and expecting a specific token type or throwing an error. also need parse-program and parse-stmt-list functions

**AI Response:**
```racket
;; Global variables for parsing state
(define current-tokens '())
(define current-index 0)

;; Get current token
(define (current-token)
  (if (< current-index (length current-tokens))
      (list-ref current-tokens current-index)
      (token 'EOF 'EOF 0)))

;; Peek at next token
(define (peek-token)
  (if (< (+ current-index 1) (length current-tokens))
      (list-ref current-tokens (+ current-index 1))
      (token 'EOF 'EOF 0)))

;; Advance to next token
(define (advance-token)
  (set! current-index (+ current-index 1)))

;; Check if current token matches expected type
(define (match-token type)
  (equal? (token-type (current-token)) type))

;; Consume expected token or raise error
(define (expect-token type)
  (if (match-token type)
      (let ([tok (current-token)])
        (advance-token)
        tok)
      (error (format "Syntax error on line ~a: expected ~a, got ~a"
                     (token-line (current-token))
                     type
                     (token-type (current-token))))))

;; Parse program: stmt-list EOF
(define (parse-program)
  (let ([stmts (parse-stmt-list)])
    (expect-token 'EOF)
    (node 'program (list stmts))))

;; Parse stmt-list: stmt stmt-list | epsilon
(define (parse-stmt-list)
  (if (or (match-token 'EOF)
          (match-token 'END))
      (node 'stmt-list '())
      (let ([stmt (parse-stmt)])
        (let ([rest (parse-stmt-list)])
          (node 'stmt-list (list stmt rest))))))
```

---

### Prompt 4: Statement Parsing Functions
**Me:**
> can you write the parse functions for the different statement types? i need parse-if-stmt, parse-while-stmt, parse-assign-stmt, parse-read-stmt, and parse-print-stmt. also need parse-single-stmt that routes to the right one

**AI Response:**
```racket
;; Parse a single statement (not compound)
(define (parse-single-stmt)
  (cond
    [(match-token 'IF) (parse-if-stmt)]
    [(match-token 'WHILE) (parse-while-stmt)]
    [(match-token 'READ) (parse-read-stmt)]
    [(match-token 'PRINT) (parse-print-stmt)]
    [(match-token 'ID) (parse-assign-stmt)]
    [else
     (error (format "Syntax error on line ~a: unexpected token ~a"
                    (token-line (current-token))
                    (token-type (current-token))))]))

;; Parse if-stmt: if expr comp-op expr then begin stmt-list end {else begin stmt-list end}
(define (parse-if-stmt)
  (expect-token 'IF)
  (let ([left-expr (parse-term)])
    (let ([comp-op (expect-token 'COMP-OP)])
      (let ([right-expr (parse-term)])
        (expect-token 'THEN)
        (expect-token 'BEGIN)
        (let ([then-stmts (parse-stmt-list)])
          (expect-token 'END)
          (if (match-token 'ELSE)
              (begin
                (advance-token)
                (expect-token 'BEGIN)
                (let ([else-stmts (parse-stmt-list)])
                  (expect-token 'END)
                  (node 'if-stmt (list left-expr comp-op right-expr then-stmts else-stmts))))
              (node 'if-stmt (list left-expr comp-op right-expr then-stmts))))))))

;; [Additional statement parsing functions]
;; [See AI_GENERATED_CODE.md for complete code]
```

---

### Prompt 5: Expression Parsing
**Me:**
> now i need the expression parsing functions. need parse-expr for handling addition/subtraction, parse-term for multiplication/division, and parse-factor for the basic stuff like ids, numbers, and parentheses. also need to handle signed numbers

**AI Response:**
```racket
;; Parse expr: term + expr | term - expr | term comp-op term | term
(define (parse-expr)
  (let ([left (parse-term)])
    (cond
      [(match-token 'PLUS)
       (let ([op (current-token)])
         (advance-token)
         (let ([right (parse-expr)])
           (node 'expr (list left op right))))]
      [(match-token 'MINUS)
       (let ([op (current-token)])
         (advance-token)
         (let ([right (parse-expr)])
           (node 'expr (list left op right))))]
      [(match-token 'COMP-OP)
       (let ([op (current-token)])
         (advance-token)
         (let ([right (parse-term)])
           (node 'expr (list left op right))))]
      [else left])))

;; [Additional expression parsing functions]
;; [See AI_GENERATED_CODE.md for complete code]
```

---

### Prompt 6: Main Parse Function
**Me:**
> need a main parse function that takes a filename, reads it, tokenizes it, and then parses it. should handle errors nicely and print "Accept" if it works

**AI Response:**
```racket
;; Main parse function that takes a filename
(define (parse filename)
  (with-handlers ([exn:fail?
                   (lambda (exn)
                     (displayln (exn-message exn)))])
    ;; Read the file
    (let ([input (file->string filename)])
      ;; Tokenize
      (set! current-tokens (tokenize input))
      (set! current-index 0)

      ;; Parse
      (let ([tree (parse-program)])
        (displayln "Accept")
        (pretty-print tree)
        tree))))
```

---

### Prompt 7: Compound Statements Bug Fix
**Me:**
> hey so test8 is failing with "unexpected token SEMI" on line 2. the test file has multiple statements on one line like "x := 1; y := 2; z := 3". i think the issue is that after parsing the first statement, the semicolon is just sitting there. how do i handle compound statements where semicolons separate multiple statements on the same line?

**AI Response:**
```racket
;; Parse stmt: if-stmt | while-stmt | assign-stmt | read-stmt | print-stmt | compound-stmt
(define (parse-stmt)
  ;; Parse the first statement
  (let ([first-stmt (parse-single-stmt)])
    ;; Check if there are more statements on the same line (semicolon)
    (if (match-token 'SEMI)
        ;; This is a compound statement
        (let loop ([stmts (list first-stmt)])
          (if (match-token 'SEMI)
              (begin
                (advance-token) ; consume semicolon
                (let ([stmt (parse-single-stmt)])
                  (loop (append stmts (list stmt)))))
              (if (= (length stmts) 1)
                  first-stmt
                  (node 'compound-stmt stmts))))
        ;; Just a single statement
        first-stmt)))
```

---

### Prompt 8: User-Friendly Testing Interface
**Me:**
> can you add a help message that prints when the file loads showing how to run the tests? and also make a run-all-tests function that runs all 8 test files automatically

**AI Response:**
```racket
;; Helper message - Displays when module loads
(displayln "")
(displayln "========================================")
(displayln "Parser for Simple Programming Language")
(displayln "========================================")
(displayln "")
(displayln "To run tests, use the following commands:")
(displayln "")
(displayln "  (parse \"test1_simple.txt\")           - Basic assignment and print")
(displayln "  (parse \"test2_if_else.txt\")          - If-else conditionals")
(displayln "  (parse \"test3_while.txt\")            - While loops")
(displayln "  (parse \"test4_complex.txt\")          - Complex expressions")
(displayln "  (parse \"test5_float.txt\")            - Floating-point numbers")
(displayln "  (parse \"test6_error.txt\")            - Syntax error (should fail)")
(displayln "  (parse \"test7_multiline_comment.txt\") - Multi-line comments")
(displayln "  (parse \"test8_compound.txt\")         - Compound statements")
(displayln "")
(displayln "Valid programs will output 'Accept' followed by the parse tree.")
(displayln "Invalid programs will show a syntax error message.")
(displayln "")
(displayln "OR run all tests at once:")
(displayln "  (run-all-tests)                        - Execute all 8 test files")
(displayln "========================================")
(displayln "")
```

---

### Prompt 9: Run All Tests Function
**Me:**
> ok last thing - can you write the actual run-all-tests function that goes through and runs all 8 test files one by one with labels?

**AI Response:**
```racket
;; Run all tests function
(define (run-all-tests)
  (displayln "")
  (displayln "========================================")
  (displayln "Running All Tests")
  (displayln "========================================")
  (displayln "")
  
  (displayln ">>> TEST 1: test1_simple.txt (Basic assignment and print)")
  (parse "test1_simple.txt")
  (displayln "")
  
  (displayln ">>> TEST 2: test2_if_else.txt (If-else conditionals)")
  (parse "test2_if_else.txt")
  (displayln "")
  
  ;; [Additional test calls]
  ;; [See AI_GENERATED_CODE.md for complete code]
  
  (displayln "========================================")
  (displayln "All Tests Complete")
  (displayln "========================================"))
```

---

## Summary

Total prompts to AI: 9  
Total lines of AI-generated code: ~470 lines  
Percentage of project from AI: ~65%  

All AI-generated code was reviewed, tested, and integrated into the final project. Some modifications were made during debugging to fix parsing issues with comparison operators and compound statements.
