# LLM Prompts and Resources Used

## Assignment Description
This document tracks all prompts given to the AI and resources consulted during the development of the parser for Program 2.

## Initial Prompt
**Date**: [Your date here]

**Prompt**:
```
For this assignment you'll be writing a parser for a simple grammar. As with the last assignment, it's as much about how you use the AI tools as it is code correctness. There are two basic approaches: You may write a recursive descent top-down parser, or use the parser generator tool brag to produce a parser. The two approaches are about equal in difficulty; one has you grappling with code, the other with documentation and dealing with the syntax-object that brag returns.

Either way, your code should have a function called parse, which takes one parameter: the name of the source code to be processed.

[Full assignment description provided]
```

## Development Prompts

### 1. Initial Implementation Request
**Prompt**: "Create a recursive descent parser for the given grammar in Racket"

**AI Response**: Created initial parser.rkt file with:
- Lexer (tokenizer) implementation
- Recursive descent parser following the grammar rules
- Parse tree structure using Racket structs
- Error handling with line number tracking

### 2. Bug Fix Request
**Prompt**: "Fix the bug in the read-id function where chars variable was being used incorrectly"

**AI Response**: Corrected the lexer's read-id function to properly accumulate characters using a renamed local variable `id-chars` instead of conflicting with the parent scope's `chars` variable.

### 3. Test File Creation
**Prompt**: "Create comprehensive test files to verify the parser works with various inputs"

**AI Response**: Created 8 test files covering:
- Simple assignments and prints
- If-else statements
- While loops
- Complex expressions with multiple operators
- Floating-point numbers
- Syntax errors
- Multi-line comments
- Compound statements (multiple statements on one line)

## Resources Consulted

### Racket Documentation
- **Racket Guide**: https://docs.racket-lang.org/guide/
  - Used for: Understanding Racket syntax, structs, and string manipulation

- **Racket Reference**: https://docs.racket-lang.org/reference/
  - Used for: File I/O operations, character functions, list operations

### Course Materials
- Course textbook sections on:
  - Recursive descent parsing
  - Lexical analysis
  - Context-free grammars
  - Top-down parsing techniques

### Parsing Concepts
- Understanding of LL(1) grammars and predictive parsing
- First and Follow sets (conceptual understanding for grammar analysis)
- Error recovery in parsers

## Implementation Decisions

### Why Recursive Descent Instead of Brag?
1. **Code transparency**: Easier to understand and explain in the video
2. **Direct mapping**: Each grammar rule maps to a function
3. **Debugging**: Simpler to trace through and fix errors
4. **Learning value**: Better demonstrates understanding of parsing concepts

### Key Design Choices
1. **Two-pass approach**: Separate lexer and parser for clean separation of concerns
2. **Token structure**: Includes line numbers for error reporting
3. **Parse tree nodes**: Generic node structure with type and children
4. **Error handling**: Uses Racket's exception handling with descriptive messages

## Challenges Encountered

### 1. Lexer Character Handling
**Issue**: Initial implementation had variable scoping issue in read-id function

**Solution**: Renamed local accumulator variable to avoid conflict with parent scope

### 2. Grammar Ambiguities
**Issue**: Distinguishing between assignment statements and compound statements when starting with ID

**Solution**: Added lookahead check to examine token following ID (ASSIGN vs SEMI)

### 3. Expression Parsing
**Issue**: Handling operator precedence correctly (*, / before +, -)

**Solution**: Structured parsing functions hierarchically: expr -> term -> factor

## Testing Strategy
1. Created test files for each major grammar construct
2. Included both valid and invalid inputs
3. Tested edge cases (multi-line comments, floating-point numbers, signed numbers)
4. Verified error messages include correct line numbers
