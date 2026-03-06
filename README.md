# Adaptive Flow

Compound engineering framework for Claude Code.
Adapts process gravity to task complexity.

## Quick Start

### 1. Requirements

- **Claude Code** (CLI)
- **jq** — Required for reliable JSON handling in hooks (`brew install jq` / `apt install jq`)
- **python3 + PyYAML** — Recommended for YAML parsing (falls back to grep if unavailable)

### 2. Install

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

### 3. First Use

Just ask Claude to do something. The framework activates automatically:

- **Simple task** (fix a typo, add a field) → Gravity 1: executes directly
- **Medium task** (add pagination, new endpoint) → Gravity 2: plans then executes
- **Complex task** (OAuth, new module) → Gravity 3: full cycle with review
- **Ambiguous task** (restructure billing) → Gravity 4: research → shape → full cycle

You don't need to memorize this — Claude reads `CLAUDE.md` and routes for you.

### 4. Make It Yours

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
│   Skills     │  Fresh-context subagents (SKILL.md)
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
├── hooks/                 # Deterministic quality gates
├── memory/                # Persistent memory files
├── templates/             # Artifact templates
├── core/                  # Reference guides (loaded on demand)
└── skills/                # 8 skills (4 workers + 4 invocable), each with SKILL.md
```

## Key Concepts

**Gravity** — Process weight proportional to task complexity (1-4).
A typo fix doesn't need a full spec-design-implement-review cycle.

**Insights** — Graduated heuristics that influence AI decisions.
Not rigid rules. "I've observed X works because Y" with high/medium/low influence.

**Skills** — Subagents that run with fresh context (`context: fork`).
Auto-discovered from `skills/*/SKILL.md`. They don't drag conversation history, keeping focus and saving tokens.

**Hooks** — Deterministic quality gates that run automatically.
Tests pass before commit. Plan exists before implementation. No relying on memory.

**Compound** — Every completed feature feeds knowledge into the next one.
Patterns, learnings, and insights accumulate and improve future work.

## Troubleshooting

**Hooks not running?**
- Verify the plugin is in the correct `plugins/` directory
- Check that `hooks/hooks.json` exists and is valid JSON
- Ensure hook scripts are executable: `chmod +x hooks/*.sh`

**YAML parsing errors?**
- Install PyYAML: `pip3 install pyyaml`
- Hooks fall back to grep-based parsing if python3/yaml unavailable, but it's less precise

**jq not found?**
- Install: `brew install jq` (macOS) / `apt install jq` (Ubuntu) / `choco install jq` (Windows)
- Hooks fall back to manual JSON escaping without jq, but jq is strongly recommended

**Gravity classification seems wrong?**
- Run `/adaptive-flow:diagnostics` to see the estimated gravity and reasoning
- The router asks for confirmation when confidence < 60%

**Memory not loading?**
- Check `memory/user-insights.yaml` is valid YAML
- Verify insights have `status: active` and correct `influence` level
- Run `/adaptive-flow:discover --status` to check memory state
