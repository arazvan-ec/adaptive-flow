# Adaptive Flow Memory — MCP Server

MCP (Model Context Protocol) server that exposes the plugin's memory as structured tools.

## Setup

Add to your `.claude/settings.json`:

```json
{
  "mcpServers": {
    "adaptive-flow-memory": {
      "command": "python3",
      "args": ["plugins/adaptive-flow/mcp/memory-server.py"],
      "env": { "ADAPTIVE_FLOW_ROOT": "plugins/adaptive-flow" }
    }
  }
}
```

## Tools

| Tool | Description |
|------|------------|
| `memory_status` | Overview: insight counts, learnings, patterns, task state |
| `memory_insights` | List/filter insights by tag, influence, status |
| `memory_learnings` | List/filter learnings by type, tag, impact |
| `memory_patterns` | List/filter code patterns by tag |
| `memory_search` | Full-text search across all memory files |

## Requirements

- Python 3.8+
- PyYAML (`pip install pyyaml`)
