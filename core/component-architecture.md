# Component Architecture Principles — Reference Guide

Equivalent to SOLID for frontend/component paradigms. Used by design-analyzer when frontend paradigm is detected.

## 5 Core Principles

### 1. Single Purpose

Each component should do one thing well. If a component has multiple responsibilities, split it.

**Question**: Does the component do one thing?

**Red Flags**:
- Component >200 lines
- Component fetches data AND renders complex UI AND handles business logic
- Component name contains "And" (e.g., UserFormAndValidation)

**Pattern**: Container/Presenter split. Hooks for logic, components for rendering.

### 2. Prop Drilling Prevention

Data should flow efficiently. Avoid passing props through components that don't use them.

**Question**: Are props passed through >2 intermediate components?

**Red Flags**:
- Same prop passed through 3+ component levels
- "Prop threading" through wrapper components
- Components accepting props only to forward them

**Pattern**: Context/Provider for shared state. Composition (children/render props) to avoid drilling.

### 3. State Colocation

State should live as close to where it's used as possible. Don't lift state higher than necessary.

**Question**: Is state as close to where it's used as possible?

**Red Flags**:
- Global state for local UI concerns (modal open/close, form values)
- State in parent that only one child uses
- Redundant state (derived values stored separately)

**Pattern**: Local state first → lift only when siblings need it → global state only for truly app-wide concerns.

### 4. Composition over Configuration

Favor composing small components over configuring large ones with many props.

**Question**: Does it use children/slots instead of growing props?

**Red Flags**:
- Component with >8 props
- Boolean props that switch between entirely different behaviors
- "variant" or "mode" props that produce vastly different output

**Pattern**: Use children/slots for flexible content. Small focused components composed together.

### 5. Side Effect Isolation

Effects (data fetching, subscriptions, DOM manipulation) should be separated from rendering logic.

**Question**: Are effects separated from rendering logic?

**Red Flags**:
- API calls mixed with JSX rendering
- Event handlers with business logic inline
- Subscriptions without cleanup

**Pattern**: Custom hooks for effects. Clear separation: hooks for "what happens", components for "what renders".

## Scorecard Template

| Component | Purpose | Drilling | State | Composition | Effects | Score |
|-----------|---------|----------|-------|-------------|---------|-------|
| {component} | OK/WARN/FAIL | OK/WARN/FAIL | OK/WARN/FAIL | OK/WARN/FAIL | OK/WARN/FAIL | X/5 |
