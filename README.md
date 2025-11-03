# Program 2: Scanner and Parser

A recursive descent parser for a simple programming language grammar, implemented in Racket.

## Project Overview

This project implements a complete lexer (scanner) and parser for a programming language that supports:
- Variables and assignment statements
- Arithmetic expressions with proper operator precedence
- Conditional statements (if-then-else)
- Loops (while)
- Input/output operations (read/print)
- Comments (multi-line /* */ style)
- Floating-point and integer numbers

## Files Included

### Core Implementation
- **parser.rkt** - Main parser implementation with lexer and recursive descent parser

### Documentation
- **LLM_PROMPTS_AND_RESOURCES.md** - All AI prompts and resources used during development
- **AI_GENERATED_CODE.md** - Complete listing of AI-generated code with modification notes
- **README.md** - This file

### Test Files
- **test1_simple.txt** - Basic assignment and print
- **test2_if_else.txt** - Conditional statement testing
- **test3_while.txt** - Loop testing
- **test4_complex.txt** - Complex expressions and multiple features
- **test5_float.txt** - Floating-point number support
- **test6_error.txt** - Syntax error detection
- **test7_multiline_comment.txt** - Multi-line comment handling
- **test8_compound.txt** - Multiple statements on one line

## How to Use

### Prerequisites
- Racket installation (DrRacket IDE recommended)
- Download from: https://racket-lang.org/

### Running the Parser

#### Option 1: Using DrRacket IDE
1. Open `parser.rkt` in DrRacket
2. Click "Run" to load the module
3. In the interactions window, type:
   ```racket
   (parse "test1_simple.txt")
   ```
4. The parser will output either:
   - "Accept" followed by the parse tree (for valid programs)
   - "Syntax error on line XX" (for invalid programs)

#### Option 2: Using Command Line
```bash
racket -e '(require "parser.rkt") (parse "test1_simple.txt")'
```

### Example Output

For a valid program like `test1_simple.txt`:
```
Accept
(node
 'program
 (list
  (node
   'stmt-list
   (list
    (node 'assign-stmt ...)
    (node 'stmt-list ...)))))
```

For an invalid program like `test6_error.txt`:
```
Syntax error on line 3: expected ASSIGN, got COMP-OP
```

## Grammar Specification

```
program -> stmt-list EOF
stmt-list -> stmt stmt-list | epsilon
stmt -> if-stmt | while-stmt | assign-stmt | read-stmt | print-stmt | compound-stmt
compound-stmt -> stmt {; stmt}*
if-stmt -> if expr comp-op expr then begin stmt-list end {else begin stmt-list end}
while-stmt -> while expr comp-op expr begin stmt-list end
assign-stmt -> id := expr
read-stmt -> read id
print-stmt -> print expr
expr -> term + expr | term - expr | term comp-op term | term
term -> factor * term | factor / term | factor
factor -> id | num | (expr)
num -> sign nonzero | sign nonzero digit* | sign nonzero digit* . digit digit*
sign -> + | - | epsilon
id -> [alpha, followed by 0 or more alphanumerics, hyphens, or underscores]
comp-op -> = | > | < | >= | <= | <>
```

### Language Features

- **Keywords**: if, then, else, begin, end, while, read, print
- **Operators**: :=, +, -, *, /, =, >, <, >=, <=, <>
- **Comments**: Multi-line /* ... */ (not nested)
- **Numbers**: Integers and floating-point with optional signs
- **Identifiers**: Start with letter, followed by letters, digits, hyphens, or underscores

### Important Rules

1. Expressions cannot cross line breaks
2. Statements can cross line breaks
3. Multiple statements can appear on the same physical line, separated by semicolons
4. Semicolons indicate another statement follows on the same line
5. Comments can span multiple lines but are not nested
6. Whitespace is not significant except to separate tokens

## Implementation Details

### Architecture
The parser uses a two-phase approach:
1. **Lexical Analysis (Lexer)**: Converts input text into a stream of tokens
2. **Syntax Analysis (Parser)**: Builds a parse tree from the token stream

### Recursive Descent Parsing
Each grammar rule is implemented as a function:
- `parse-program` - Entry point
- `parse-stmt-list` - Statement sequences
- `parse-stmt` - Individual statements
- `parse-expr` - Expressions with addition/subtraction
- `parse-term` - Terms with multiplication/division
- `parse-factor` - Basic elements (variables, numbers, parenthesized expressions)

### Error Handling
- Tracks line numbers throughout lexing and parsing
- Provides descriptive error messages
- Reports the line where syntax error occurred

## Testing

Run all test files to verify the parser:

```racket
(parse "test1_simple.txt")      ; Should accept
(parse "test2_if_else.txt")     ; Should accept
(parse "test3_while.txt")       ; Should accept
(parse "test4_complex.txt")     ; Should accept
(parse "test5_float.txt")       ; Should accept
(parse "test6_error.txt")       ; Should report error on line 3
(parse "test7_multiline_comment.txt")  ; Should accept
(parse "test8_compound.txt")    ; Should accept
```

## Development Process

This parser was developed using AI assistance (Claude Code). The development process included:

1. Initial implementation of lexer and parser structure
2. Bug fix in the lexer's identifier reading function
3. Creation of comprehensive test suite
4. Documentation of all AI interactions and generated code

For complete details, see:
- `LLM_PROMPTS_AND_RESOURCES.md` for development process
- `AI_GENERATED_CODE.md` for code attribution

## Future Enhancements

Possible improvements include:
- Better error recovery to report multiple errors
- More detailed parse tree with position information
- Pretty-printer for the parse tree
- Interpreter to execute parsed programs
- Additional semantic analysis

## Author

Cole Hanson
CS441
11/2/2025

## License

This code is for educational purposes as part of a course assignment.
