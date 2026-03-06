# Memory System — Taxonomy

Adaptive Flow uses a persistent memory system organized by type.

## Memory Files

| File | Type | Description | Loaded |
|------|------|-------------|--------|
| `user-insights.yaml` | Entity | User's meta-knowledge about working with AI | Tier 1 (high), Tier 2 (all) |
| `learnings.yaml` | Episodic | Technical lessons from completed features | Tier 2 (gravity 2+) |
| `patterns.yaml` | Semantic | Reusable code patterns from this project | Tier 2 (gravity 2+) |
| `discovered-insights.yaml` | Episodic | AI-proposed insights pending user review | On demand |
| `architecture-profile.yaml` | Entity | Detected stack and conventions | Tier 1 (always) |
| `next-briefing.md` | Episodic | Briefing for next task (from compound-capture) | Tier 2 (gravity 2+) |
| `briefings/` | Archive | Historical briefings (date-stamped) | On demand |
| `current-task/` | Working | Active task artifacts (meta, spec, design, tasks) | Tier 1 (meta only) |
| `framework-analysis.md` | Archived | See `docs/improvement-v3/01-analysis.md` | Not loaded |

## Memory Types

- **Entity**: Stable knowledge about the user or project (rarely changes)
- **Episodic**: Event-based knowledge captured per feature (grows over time)
- **Semantic**: Extracted patterns and abstractions (refined over time)
- **Working**: Temporary artifacts for the current task (cleared between tasks)
- **Archive**: Historical data preserved for reference

## Loading Tiers

- **Tier 1** (session-init.sh): High-influence insights, architecture profile, current task meta
- **Tier 2** (flow activation): Full insights, learnings, patterns, briefing — loaded by gravity 2+ flows
- **Tier 3** (on-demand): Core guides — triggered by pre-write-guard.sh file patterns

## Decay Policy

- Insights: `last_validated` checked during compound-capture; stale after 5 features without validation
- Learnings: No automatic decay; reviewed during planning phases
- Patterns: `usage_count` tracked; low-usage patterns may be cleaned up manually
- Briefings: Archived with date; old briefings preserved but not loaded automatically
