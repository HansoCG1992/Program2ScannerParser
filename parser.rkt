#lang racket

(provide parse run-all-tests)

;; Token structure: (token-type value line-number)
(struct token (type value line) #:transparent)

;; Parse tree node structure
(struct node (type children) #:transparent)

;; Global variables for parsing state
(define current-tokens '())
(define current-index 0)

;; ============================================================================
;; LEXER
;; ============================================================================

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
  (define input-chars (string->list input))
  (define len (length input-chars))
  (define tokens '())
  (define line 1)
  (define pos 0)

  (define (peek)
    (if (< pos len) (list-ref input-chars pos) #f))

  (define (peek-ahead n)
    (if (< (+ pos n) len) (list-ref input-chars (+ pos n)) #f))

  (define (advance)
    (set! pos (+ pos 1)))

  ;; Skip whitespace (but track newlines)
  (define (skip-whitespace)
    (let loop ()
      (cond
        [(>= pos len) (void)]
        [(equal? (peek) #\newline)
         (set! line (+ line 1))
         (advance)
         (loop)]
        [(whitespace? (peek))
         (advance)
         (loop)]
        [else (void)])))

  ;; Skip comments /* ... */
  (define (skip-comment)
    (when (and (equal? (peek) #\/)
               (equal? (peek-ahead 1) #\*))
      (advance) ; skip /
      (advance) ; skip *
      (let loop ()
        (cond
          [(>= pos len)
           (error "Unterminated comment")]
          [(and (equal? (peek) #\*)
                (equal? (peek-ahead 1) #\/))
           (advance) ; skip *
           (advance) ; skip /
           ]
          [(equal? (peek) #\newline)
           (set! line (+ line 1))
           (advance)
           (loop)]
          [else
           (advance)
           (loop)]))))

  ;; Read identifier or keyword
  (define (read-id)
    (let loop ([id-chars '()])
      (cond
        [(>= pos len)
         (list->string (reverse id-chars))]
        [(and (null? id-chars) (alpha? (peek)))
         (let ([ch (peek)])
           (advance)
           (loop (cons ch id-chars)))]
        [(and (not (null? id-chars))
              (or (alphanumeric? (peek))
                  (equal? (peek) #\-)
                  (equal? (peek) #\_)))
         (let ([ch (peek)])
           (advance)
           (loop (cons ch id-chars)))]
        [else
         (list->string (reverse id-chars))])))

  ;; Read number (integer or float)
  (define (read-number)
    (let loop ([num-chars '()] [has-dot #f])
      (cond
        [(>= pos len)
         (list->string (reverse num-chars))]
        [(and (equal? (peek) #\.) (not has-dot))
         (let ([ch (peek)])
           (advance)
           (loop (cons ch num-chars) #t))]
        [(digit? (peek))
         (let ([ch (peek)])
           (advance)
           (loop (cons ch num-chars) has-dot))]
        [else
         (list->string (reverse num-chars))])))

  ;; Main tokenization loop
  (let main-loop ()
    (skip-whitespace)
    (skip-comment)
    (skip-whitespace)

    (if (>= pos len)
        (reverse (cons (token 'EOF 'EOF line) tokens))

        (let ([ch (peek)])
          (cond
            ;; Check for comment start
            [(and (equal? ch #\/)
                  (equal? (peek-ahead 1) #\*))
             (skip-comment)
             (main-loop)]

            ;; Two-character operators
            [(and (equal? ch #\:)
                  (equal? (peek-ahead 1) #\=))
             (advance)
             (advance)
             (set! tokens (cons (token 'ASSIGN ":=" line) tokens))
             (main-loop)]

            [(and (equal? ch #\>)
                  (equal? (peek-ahead 1) #\=))
             (advance)
             (advance)
             (set! tokens (cons (token 'COMP-OP ">=" line) tokens))
             (main-loop)]

            [(and (equal? ch #\<)
                  (equal? (peek-ahead 1) #\=))
             (advance)
             (advance)
             (set! tokens (cons (token 'COMP-OP "<=" line) tokens))
             (main-loop)]

            [(and (equal? ch #\<)
                  (equal? (peek-ahead 1) #\>))
             (advance)
             (advance)
             (set! tokens (cons (token 'COMP-OP "<>" line) tokens))
             (main-loop)]

            ;; Single-character operators and punctuation
            [(equal? ch #\=)
             (advance)
             (set! tokens (cons (token 'COMP-OP "=" line) tokens))
             (main-loop)]

            [(equal? ch #\>)
             (advance)
             (set! tokens (cons (token 'COMP-OP ">" line) tokens))
             (main-loop)]

            [(equal? ch #\<)
             (advance)
             (set! tokens (cons (token 'COMP-OP "<" line) tokens))
             (main-loop)]

            [(equal? ch #\+)
             (advance)
             (set! tokens (cons (token 'PLUS "+" line) tokens))
             (main-loop)]

            [(equal? ch #\-)
             (advance)
             (set! tokens (cons (token 'MINUS "-" line) tokens))
             (main-loop)]

            [(equal? ch #\*)
             (advance)
             (set! tokens (cons (token 'MULT "*" line) tokens))
             (main-loop)]

            [(equal? ch #\/)
             (advance)
             (set! tokens (cons (token 'DIV "/" line) tokens))
             (main-loop)]

            [(equal? ch #\()
             (advance)
             (set! tokens (cons (token 'LPAREN "(" line) tokens))
             (main-loop)]

            [(equal? ch #\))
             (advance)
             (set! tokens (cons (token 'RPAREN ")" line) tokens))
             (main-loop)]

            [(equal? ch #\;)
             (advance)
             (set! tokens (cons (token 'SEMI ";" line) tokens))
             (main-loop)]

            ;; Identifiers and keywords
            [(alpha? ch)
             (let ([id (read-id)])
               (if (member id keywords)
                   (set! tokens (cons (token (string->symbol (string-upcase id)) id line) tokens))
                   (set! tokens (cons (token 'ID id line) tokens)))
               (main-loop))]

            ;; Numbers
            [(digit? ch)
             (let ([num (read-number)])
               (set! tokens (cons (token 'NUM num line) tokens))
               (main-loop))]

            [else
             (error (format "Syntax error on line ~a: unexpected character '~a'" line ch))]))))

  (reverse tokens))

;; ============================================================================
;; PARSER
;; ============================================================================

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

;; Parse while-stmt: while expr comp-op expr begin stmt-list end
(define (parse-while-stmt)
  (expect-token 'WHILE)
  (let ([left-expr (parse-term)])
    (let ([comp-op (expect-token 'COMP-OP)])
      (let ([right-expr (parse-term)])
        (expect-token 'BEGIN)
        (let ([stmts (parse-stmt-list)])
          (expect-token 'END)
          (node 'while-stmt (list left-expr comp-op right-expr stmts)))))))

;; Parse assign-stmt: id := expr
(define (parse-assign-stmt)
  (let ([id (expect-token 'ID)])
    (expect-token 'ASSIGN)
    (let ([expr (parse-expr)])
      (node 'assign-stmt (list id expr)))))

;; Parse read-stmt: read id
(define (parse-read-stmt)
  (expect-token 'READ)
  (let ([id (expect-token 'ID)])
    (node 'read-stmt (list id))))

;; Parse print-stmt: print expr
(define (parse-print-stmt)
  (expect-token 'PRINT)
  (let ([expr (parse-expr)])
    (node 'print-stmt (list expr))))

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

;; Parse term: factor * term | factor / term | factor
(define (parse-term)
  (let ([left (parse-factor)])
    (cond
      [(match-token 'MULT)
       (let ([op (current-token)])
         (advance-token)
         (let ([right (parse-term)])
           (node 'term (list left op right))))]
      [(match-token 'DIV)
       (let ([op (current-token)])
         (advance-token)
         (let ([right (parse-term)])
           (node 'term (list left op right))))]
      [else left])))

;; Parse factor: id | num | (expr)
(define (parse-factor)
  (cond
    [(match-token 'ID)
     (let ([id (current-token)])
       (advance-token)
       (node 'factor (list id)))]
    [(match-token 'NUM)
     (let ([num (current-token)])
       (advance-token)
       (node 'factor (list num)))]
    [(match-token 'LPAREN)
     (advance-token)
     (let ([expr (parse-expr)])
       (expect-token 'RPAREN)
       (node 'factor (list expr)))]
    [(match-token 'PLUS)
     ;; Signed number
     (advance-token)
     (let ([num (expect-token 'NUM)])
       (node 'factor (list (token 'NUM (string-append "+" (token-value num)) (token-line num)))))]
    [(match-token 'MINUS)
     ;; Signed number
     (advance-token)
     (let ([num (expect-token 'NUM)])
       (node 'factor (list (token 'NUM (string-append "-" (token-value num)) (token-line num)))))]
    [else
     (error (format "Syntax error on line ~a: expected factor, got ~a"
                    (token-line (current-token))
                    (token-type (current-token))))]))

;; ============================================================================
;; MAIN PARSE FUNCTION
;; ============================================================================

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

;; ============================================================================
;; HELPER MESSAGE - Displays when module loads
;; ============================================================================

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

;; ============================================================================
;; RUN ALL TESTS - Convenience function to run all test files
;; ============================================================================

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
  
  (displayln ">>> TEST 3: test3_while.txt (While loops)")
  (parse "test3_while.txt")
  (displayln "")
  
  (displayln ">>> TEST 4: test4_complex.txt (Complex expressions)")
  (parse "test4_complex.txt")
  (displayln "")
  
  (displayln ">>> TEST 5: test5_float.txt (Floating-point numbers)")
  (parse "test5_float.txt")
  (displayln "")
  
  (displayln ">>> TEST 6: test6_error.txt (Syntax error - should fail)")
  (parse "test6_error.txt")
  (displayln "")
  
  (displayln ">>> TEST 7: test7_multiline_comment.txt (Multi-line comments)")
  (parse "test7_multiline_comment.txt")
  (displayln "")
  
  (displayln ">>> TEST 8: test8_compound.txt (Compound statements)")
  (parse "test8_compound.txt")
  (displayln "")
  
  (displayln "========================================")
  (displayln "All Tests Complete")
  (displayln "========================================"))