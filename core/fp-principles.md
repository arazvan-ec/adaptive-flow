# Functional Programming Principles — Reference Guide

Equivalent to SOLID for functional paradigms. Used by design-analyzer when FP paradigm is detected.

## 5 Core Principles

### 1. Pure Functions

A function is pure when its output depends only on its inputs and it produces no side effects.

**Question**: Does it have side effects or depend on external state?

**Red Flags**:
- Reads/writes global state
- Makes network calls inside business logic
- Depends on current time or random values without injection
- Mutates input arguments

**Pattern**: Push side effects to the edges (IO at boundaries, pure logic in core).

### 2. Immutability

Data structures should not be mutated after creation. Produce new values instead.

**Question**: Does it mutate data in place?

**Red Flags**:
- Array.push/splice instead of spread/concat
- Object property assignment instead of spread
- Mutable class fields without clear ownership

**Pattern**: Use spread operators, Object.freeze, or immutable libraries.

### 3. Composability

Functions should be small, focused, and composable via piping or chaining.

**Question**: Can it be easily combined with other functions?

**Red Flags**:
- Functions with >3 parameters
- Functions that do multiple unrelated things
- Deeply nested conditionals

**Pattern**: Small functions → compose with pipe/flow. Use currying for partial application.

### 4. Type Safety

Inputs and outputs should be well-typed. Use the type system to prevent invalid states.

**Question**: Are inputs/outputs well-typed? Can invalid data be represented?

**Red Flags**:
- `any` types in TypeScript
- Stringly-typed data (status: string instead of union type)
- Missing null/undefined checks

**Pattern**: Discriminated unions, branded types, Result/Either types for error handling.

### 5. Referential Transparency

An expression is referentially transparent if it can be replaced by its value without changing behavior.

**Question**: Can you replace the function call with its return value?

**Red Flags**:
- Same input produces different output
- Function behavior changes based on call order
- Hidden dependencies via closures over mutable state

**Pattern**: Treat functions as mathematical transformations: same input → same output, always.

## Scorecard Template

| Function/Module | Pure | Immutable | Composable | Typed | Transparent | Score |
|----------------|------|-----------|------------|-------|-------------|-------|
| {module} | OK/WARN/FAIL | OK/WARN/FAIL | OK/WARN/FAIL | OK/WARN/FAIL | OK/WARN/FAIL | X/5 |
