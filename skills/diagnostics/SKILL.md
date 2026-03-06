---
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Skill: diagnostics

Dry-run diagnostic tool. Shows estimated gravity, applicable flow, active insights, and memory state without executing any flow.

## Invocation

```
/adaptive-flow:diagnostics                    # Diagnose current state
/adaptive-flow:diagnostics "task description" # Estimate gravity for a hypothetical task
```

## Process

```
1. Load current state:
   - Read memory/user-insights.yaml → count active insights by influence level
   - Read memory/learnings.yaml → count learnings by type
   - Read memory/patterns.yaml → count patterns
   - Read memory/architecture-profile.yaml → show stack summary
   - Read memory/current-task/meta.yaml → show active task (if any)
   - Check memory/next-briefing.md → exists or not

2. If task description provided:
   - Estimate gravity (1-4) with reasoning
   - Show which flow would be activated
   - Show which insights would apply (filtered by when_to_apply for the relevant phases)
   - Show which learnings are relevant

3. Output diagnostic report
```

## Output Format

```markdown
# Adaptive Flow — Diagnostics

## Memory State
- **User insights**: {N} active ({N} high, {N} medium, {N} low), {N} paused
- **Learnings**: {N} total ({N} pattern, {N} anti-pattern, {N} boundary)
- **Patterns**: {N} registered
- **Architecture profile**: {exists/missing} — {stack summary if exists}
- **Current task**: {active task name or "none"}
- **Next briefing**: {exists/missing}

## Estimated Gravity (if task provided)
- **Task**: "{description}"
- **Gravity**: {1-4}
- **Reasoning**: {why this gravity}
- **Flow**: {flow file}

## Applicable Insights
- [high] {id}: {observation}
- [medium] {id}: {observation}

## Relevant Learnings
- [{type}] {id}: {description}

## Health Checks
- [ ] jq available: {yes/no}
- [ ] python3+yaml available: {yes/no}
- [ ] hooks executable: {yes/no}
- [ ] plugin.json valid: {yes/no}
```
