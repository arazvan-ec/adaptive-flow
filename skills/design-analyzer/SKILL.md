---
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
  - Task
---

# Skill: design-analyzer

> **Help**: Analyze code against design principles appropriate to your paradigm. Usage: `/adaptive-flow:design-analyzer [--mode=baseline|design|verify] [--paradigm=oop|fp|frontend|microservices]`

Pluggable design analysis that adapts to the project's paradigm.
Detects paradigm from architecture-profile.yaml or accepts explicit override.

## Paradigm Detection

```
1. Check memory/architecture-profile.yaml for detected_patterns
2. Infer paradigm:
   - OOP: classes, inheritance, repository/service patterns → SOLID framework
   - FP: pure functions, composition, immutable data → Composition framework
   - Frontend: components, hooks, state management → Component Architecture framework
   - Microservices: bounded contexts, APIs, event-driven → Bounded Context framework
3. If ambiguous, ask user or default to SOLID
```

## Frameworks

### SOLID (OOP — default)

Uses `core/solid-reference.md`. Same analysis as solid-analyzer skill.

| Principle | Question |
|-----------|----------|
| Single Responsibility | Does it have more than one reason to change? |
| Open/Closed | Must you modify existing code to add new behavior? |
| Liskov Substitution | Are subtypes interchangeable? |
| Interface Segregation | Do clients depend on methods they don't use? |
| Dependency Inversion | Does it depend on concretions instead of abstractions? |

### Composition (FP)

Uses `core/fp-principles.md` (if available).

| Principle | Question |
|-----------|----------|
| Pure Functions | Does it have side effects or depend on external state? |
| Immutability | Does it mutate data in place? |
| Composability | Can it be easily combined with other functions? |
| Type Safety | Are inputs/outputs well-typed? |
| Referential Transparency | Can you replace the call with its result? |

### Component Architecture (Frontend)

Uses `core/component-architecture.md` (if available).

| Principle | Question |
|-----------|----------|
| Single Purpose | Does the component do one thing? |
| Prop Drilling | Are props passed through >2 intermediate components? |
| State Colocation | Is state as close to where it's used as possible? |
| Composition over Configuration | Does it use children/slots instead of growing props? |
| Side Effect Isolation | Are effects separated from rendering logic? |

### Bounded Contexts (Microservices)

| Principle | Question |
|-----------|----------|
| Context Boundaries | Does the service own its data? |
| API Contract | Is the interface stable and versioned? |
| Event-Driven | Are cross-service communications async when possible? |
| Failure Isolation | Does one service failure cascade to others? |
| Data Ownership | Does each service have its own persistence? |

## Modes

Modes work the same as solid-analyzer (baseline, design, verify) but apply the detected framework.

## Invocation

```
/adaptive-flow:design-analyzer                              # Auto-detect paradigm, baseline mode
/adaptive-flow:design-analyzer --paradigm=fp                # Force FP analysis
/adaptive-flow:design-analyzer --mode=design                # Validate a proposed design
/adaptive-flow:design-analyzer --mode=verify                # Verify code matches design
```

## Backward Compatibility

`/adaptive-flow:solid-analyzer` continues to work and always uses the SOLID framework.
`/adaptive-flow:design-analyzer` is the recommended evolution with auto-detection.
