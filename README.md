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
│   Hooks      │  Automatic quality gates
│  (validation)│  pre-commit / post-plan / pre-work / post-review
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

## Structure

```
adaptive-flow/
├── CLAUDE.md              # Entry point (~100 lines, always loaded)
├── flows/                 # 4 gravity-based processes
├── workers/               # 4 fresh-context subagents
├── hooks/                 # 4 deterministic quality gates
├── memory/                # 4 persistent memory files
├── templates/             # 4 artifact templates
├── core/                  # 4 reference guides (loaded on demand)
└── skills/                # 4 invocable skills
```

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
