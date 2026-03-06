# D5: Agent Teams Evaluation for Gravity 3+

**Date**: 2026-03-06
**Decision**: D2 — Evaluation only in v3, no implementation

## Current Architecture: Sequential Skills

```
Flow → planner (fork) → implementer (fork) → reviewer (fork)
```

Each skill runs as a forked subagent with fresh context. Communication happens through artifacts (spec.md, design.md, tasks.md).

## Agent Teams Alternative

```
Flow → [planner + implementer + reviewer] as teammates
     → shared context, parallel awareness
```

### Potential Benefits

1. **Reviewer awareness during implementation**: Reviewer could flag issues as they happen
2. **Planner adjustments**: Planner could update plan based on implementation discoveries
3. **Reduced context loss**: Teammates share conversational context

### Costs and Risks

1. **Token cost**: 5-7x increase (each agent processes full shared context)
2. **Complexity**: Coordination logic, conflict resolution, turn management
3. **Diminishing returns**: For most tasks, sequential flow is sufficient
4. **Debugging**: Harder to trace decisions through multi-agent interactions

### When Agent Teams Would Add Value

| Scenario | Value | Current Alternative |
|----------|-------|-------------------|
| G3 with iterative reviewer feedback | Medium | reviewer → implementer loop already works |
| G4 with evolving requirements | High | shape-first flow handles this |
| Real-time code review | Medium | post-write-check provides lightweight version |
| Parallel specialist analysis | High | No current equivalent |

### Recommendation

**Not for v3.** The sequential skill model with artifact-based communication works well. The token cost (5-7x) doesn't justify the marginal improvement for most tasks.

**For v4, consider a limited "review panel" model**: Multiple reviewer perspectives running in parallel for G3+ tasks. This captures the highest-value use case (parallel specialist analysis) without the full complexity of Agent Teams.

This is partially addressed by D6 (multi-perspective review configurable by gravity).
