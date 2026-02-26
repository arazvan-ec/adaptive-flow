# Adaptive Flow

Compound engineering framework for Claude Code.
Adapts process gravity to task complexity.

## Quick Start

### 1. Install

Place the `adaptive-flow/` directory inside your project's `plugins/` folder
(or wherever your Claude Code plugins live).

```
your-project/
├── .claude/
│   └── settings.json    ← may reference plugins
├── plugins/
│   └── adaptive-flow/   ← this plugin
└── src/
```

### 2. First Use

Just ask Claude to do something. The framework activates automatically:

- **Simple task** (fix a typo, add a field) → Gravity 1: executes directly
- **Medium task** (add pagination, new endpoint) → Gravity 2: plans then executes
- **Complex task** (OAuth, new module) → Gravity 3: full cycle with review
- **Ambiguous task** (restructure billing) → Gravity 4: research → shape → full cycle

You don't need to memorize this — Claude reads `CLAUDE.md` and routes for you.

### 3. Make It Yours

Add your first insight to teach the AI how YOU prefer to work:

```
/adaptive-flow:insights-manager --add
```

Example insights:
- "When I ask for SOLID analysis, the resulting code scales better"
- "I prefer small functions under 20 lines"
- "Always write tests before implementation"

The more insights you add, the better the AI adapts to your style.

## How It Works

```
User Request
     │
     ▼
┌─────────────┐
│  CLAUDE.md   │  Classify gravity (1-4)
│  (routing)   │  Load relevant insights
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Flow      │  Process matched to gravity
│  (process)   │  direct / plan-execute / full-cycle / shape-first
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Workers    │  Fresh-context subagents
│  (execution) │  planner / implementer / reviewer / researcher
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Hooks      │  Automatic quality gates (via .claude/settings.json)
│  (validation)│  pre-commit-guard / post-artifact-check / on-stop
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Memory     │  Knowledge persists between sessions
│  (learning)  │  insights / learnings / patterns
└─────────────┘
```

## Available Skills

| Skill | Command | What it does |
|-------|---------|-------------|
| Insights Manager | `/adaptive-flow:insights-manager` | Add, review, pause, retire user insights |
| SOLID Analyzer | `/adaptive-flow:solid-analyzer` | Analyze code against SOLID principles |
| Compound Capture | `/adaptive-flow:compound-capture` | Extract learnings after completing a feature |
| Discover | `/adaptive-flow:discover --seed` | Analyze your stack and bootstrap memory |

## Getting Started (for existing users)

The framework comes with 8 starter insights in `memory/user-insights.yaml` that you can
adjust, pause, or retire. To add your own: `/adaptive-flow:insights-manager --add`.
To analyze your stack and bootstrap project-specific memory: `/adaptive-flow:discover --seed`.

## Structure

```
adaptive-flow/
├── CLAUDE.md              # Entry point (routing + memory pointers, ~35 lines)
├── .claude/
│   └── settings.json      # Claude Code hooks configuration
├── flows/                 # 4 gravity-based processes
├── workers/               # 4 fresh-context subagents
├── hooks/                 # Quality gate scripts (registered via .claude/settings.json)
├── memory/                # Persistent memory files
├── templates/             # Artifact templates
├── core/                  # Reference guides (loaded on demand)
└── skills/                # Invocable skills
```

## Workers (fresh-context subagents)

| Worker | When | Context received |
|--------|------|-----------------|
| planner | Gravity 2-4 | Flow + existing specs + planning insights |
| implementer | Gravity 2-4 | Plan + implementation insights |
| reviewer | Gravity 3-4 | Code + specs + review insights |
| researcher | When analysis needed | Specific question |

Workers run with `context: fork` — fresh context, return only summary.

## Compound: Every task improves the next

After completing a gravity 3+ task, run `/adaptive-flow:compound-capture` to:
- Extract patterns and anti-patterns → `memory/learnings.yaml`
- Propose discovered insights → `memory/discovered-insights.yaml`
- Generate briefing for the next task

## Key Concepts

**Gravity** — Process weight proportional to task complexity (1-4).
A typo fix doesn't need a full spec-design-implement-review cycle.

**Insights** — Graduated heuristics that influence AI decisions.
Not rigid rules. "I've observed X works because Y" with high/medium/low influence.

**Workers** — Subagents that run with fresh context (`context: fork`).
They don't drag conversation history, keeping focus and saving tokens.

**Hooks** — Deterministic quality gates that run automatically.
Tests pass before commit. Plan exists before implementation. No relying on memory.

**Compound** — Every completed feature feeds knowledge into the next one.
Patterns, learnings, and insights accumulate and improve future work.
