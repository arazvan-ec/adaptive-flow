#!/usr/bin/env python3
"""
Adaptive Flow Memory MCP Server

Exposes the plugin's memory system (insights, learnings, patterns) as
MCP tools for structured queries. Runs as a stdio MCP server.

Tools provided:
  - memory_search: Search across all memory files
  - memory_insights: List/filter user insights
  - memory_learnings: List/filter learnings
  - memory_patterns: List/filter patterns
  - memory_status: Overview of memory state

Usage:
  Add to .claude/settings.json:
  {
    "mcpServers": {
      "adaptive-flow-memory": {
        "command": "python3",
        "args": ["plugins/adaptive-flow/mcp/memory-server.py"],
        "env": { "ADAPTIVE_FLOW_ROOT": "plugins/adaptive-flow" }
      }
    }
  }
"""

import json
import os
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


# ── Memory root resolution ─────────────────────────────────────────

def get_memory_dir():
    root = os.environ.get("ADAPTIVE_FLOW_ROOT", os.environ.get("CLAUDE_PLUGIN_ROOT", "."))
    return Path(root) / "memory"


def load_yaml(filepath):
    """Load a YAML file, return dict or empty dict on failure."""
    path = Path(filepath)
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    if yaml:
        try:
            return yaml.safe_load(text) or {}
        except Exception:
            return {}
    # Fallback: very basic parsing for simple YAML lists
    return {"_raw": text}


# ── Tool implementations ───────────────────────────────────────────

def tool_memory_status(_args):
    """Overview of memory state."""
    mem = get_memory_dir()

    insights_data = load_yaml(mem / "user-insights.yaml")
    insights = insights_data.get("insights", [])
    active = [i for i in insights if i.get("status") == "active"]
    high = [i for i in active if i.get("influence") == "high"]
    medium = [i for i in active if i.get("influence") == "medium"]
    low = [i for i in active if i.get("influence") == "low"]
    paused = [i for i in insights if i.get("status") == "paused"]

    learnings_data = load_yaml(mem / "learnings.yaml")
    learnings = learnings_data.get("learnings", [])
    patterns_count = len([l for l in learnings if l.get("type") == "pattern"])
    anti_count = len([l for l in learnings if l.get("type") == "anti-pattern"])
    boundary_count = len([l for l in learnings if l.get("type") == "boundary"])

    pats_data = load_yaml(mem / "patterns.yaml")
    pats = pats_data.get("patterns", [])

    disc_data = load_yaml(mem / "discovered-insights.yaml")
    disc = disc_data.get("insights", [])
    proposed = [d for d in disc if d.get("status") == "proposed"]

    arch_exists = (mem / "architecture-profile.yaml").exists()
    briefing_exists = (mem / "next-briefing.md").exists()
    meta_exists = (mem / "current-task" / "meta.yaml").exists()

    arch_summary = ""
    if arch_exists:
        arch_data = load_yaml(mem / "architecture-profile.yaml")
        stack = arch_data.get("stack", arch_data)
        parts = []
        for k in ["language", "framework", "orm", "test_framework"]:
            if k in stack:
                parts.append(f"{k}: {stack[k]}")
        arch_summary = ", ".join(parts) if parts else "present"

    task_info = "none"
    if meta_exists:
        meta = load_yaml(mem / "current-task" / "meta.yaml")
        name = meta.get("name", "unknown")
        gravity = meta.get("gravity", "?")
        task_info = f"{name} (gravity {gravity})"

    return (
        f"# Adaptive Flow — Memory Status\n\n"
        f"## Insights\n"
        f"- Active: {len(active)} ({len(high)} high, {len(medium)} medium, {len(low)} low)\n"
        f"- Paused: {len(paused)}\n"
        f"- Discovered pending: {len(proposed)}\n\n"
        f"## Learnings\n"
        f"- Total: {len(learnings)} ({patterns_count} pattern, {anti_count} anti-pattern, {boundary_count} boundary)\n\n"
        f"## Code Patterns\n"
        f"- Registered: {len(pats)}\n\n"
        f"## Architecture Profile\n"
        f"- {'Present — ' + arch_summary if arch_exists else 'Not generated yet'}\n\n"
        f"## Current Task\n"
        f"- {task_info}\n\n"
        f"## Next Briefing\n"
        f"- {'Exists' if briefing_exists else 'Not generated yet'}\n"
    )


def tool_memory_insights(args):
    """List/filter user insights."""
    mem = get_memory_dir()
    data = load_yaml(mem / "user-insights.yaml")
    insights = data.get("insights", [])

    tag_filter = args.get("tag", "").lower()
    influence_filter = args.get("influence", "").lower()
    status_filter = args.get("status", "active").lower()

    results = []
    for i in insights:
        if status_filter and i.get("status", "") != status_filter:
            continue
        if influence_filter and i.get("influence", "") != influence_filter:
            continue
        if tag_filter and tag_filter not in [t.lower() for t in i.get("tags", [])]:
            continue
        results.append(i)

    if not results:
        return "No insights match the given filters."

    lines = [f"# User Insights ({len(results)} results)\n"]
    for i in results:
        tags = ", ".join(i.get("tags", []))
        lines.append(f"- `{i.get('id')}` [{i.get('influence')}]: {i.get('observation')} — [{tags}]")

    return "\n".join(lines)


def tool_memory_learnings(args):
    """List/filter learnings."""
    mem = get_memory_dir()
    data = load_yaml(mem / "learnings.yaml")
    learnings = data.get("learnings", [])

    type_filter = args.get("type", "").lower()
    tag_filter = args.get("tag", "").lower()
    impact_filter = args.get("impact", "").lower()

    results = []
    for l in learnings:
        if type_filter and l.get("type", "") != type_filter:
            continue
        if impact_filter and l.get("impact", "") != impact_filter:
            continue
        if tag_filter and tag_filter not in [t.lower() for t in l.get("tags", [])]:
            continue
        results.append(l)

    if not results:
        return "No learnings match the given filters."

    lines = [f"# Learnings ({len(results)} results)\n"]
    for l in results:
        tags = ", ".join(l.get("tags", []))
        lines.append(f"- `{l.get('id')}` [{l.get('type')}] ({l.get('impact')}): {l.get('description')} — [{tags}]")

    return "\n".join(lines)


def tool_memory_patterns(args):
    """List/filter code patterns."""
    mem = get_memory_dir()
    data = load_yaml(mem / "patterns.yaml")
    patterns = data.get("patterns", [])

    tag_filter = args.get("tag", "").lower()

    results = []
    for p in patterns:
        if tag_filter and tag_filter not in [t.lower() for t in p.get("tags", [])]:
            continue
        results.append(p)

    if not results:
        return "No patterns match the given filters."

    lines = [f"# Code Patterns ({len(results)} results)\n"]
    for p in results:
        lines.append(f"- `{p.get('id')}`: **{p.get('name')}** — {p.get('description')}")
        lines.append(f"  Example: `{p.get('example_file')}` | Used: {p.get('usage_count', 0)}x")

    return "\n".join(lines)


def tool_memory_search(args):
    """Search across all memory files."""
    query = args.get("query", "").lower()
    if not query:
        return "Please provide a search query."

    mem = get_memory_dir()
    results = {"insights": [], "learnings": [], "patterns": [], "discovered": []}

    # Search insights
    data = load_yaml(mem / "user-insights.yaml")
    for i in data.get("insights", []):
        searchable = " ".join([
            str(i.get("observation", "")),
            str(i.get("reasoning", "")),
            " ".join(i.get("tags", []))
        ]).lower()
        if query in searchable:
            results["insights"].append(i)

    # Search learnings
    data = load_yaml(mem / "learnings.yaml")
    for l in data.get("learnings", []):
        searchable = " ".join([
            str(l.get("description", "")),
            str(l.get("context", "")),
            " ".join(l.get("tags", []))
        ]).lower()
        if query in searchable:
            results["learnings"].append(l)

    # Search patterns
    data = load_yaml(mem / "patterns.yaml")
    for p in data.get("patterns", []):
        searchable = " ".join([
            str(p.get("name", "")),
            str(p.get("description", "")),
            " ".join(p.get("tags", []))
        ]).lower()
        if query in searchable:
            results["patterns"].append(p)

    # Search discovered insights
    data = load_yaml(mem / "discovered-insights.yaml")
    for d in data.get("insights", []):
        searchable = " ".join([
            str(d.get("observation", "")),
            str(d.get("evidence", ""))
        ]).lower()
        if query in searchable:
            results["discovered"].append(d)

    total = sum(len(v) for v in results.values())
    if total == 0:
        return f'No results found for "{query}".'

    lines = [f'# Search Results for "{query}" ({total} total)\n']

    if results["insights"]:
        lines.append(f"## Insights ({len(results['insights'])} matches)")
        for i in results["insights"]:
            lines.append(f"- `{i.get('id')}` [{i.get('influence')}]: {i.get('observation')}")

    if results["learnings"]:
        lines.append(f"\n## Learnings ({len(results['learnings'])} matches)")
        for l in results["learnings"]:
            lines.append(f"- `{l.get('id')}` [{l.get('type')}]: {l.get('description')}")

    if results["patterns"]:
        lines.append(f"\n## Patterns ({len(results['patterns'])} matches)")
        for p in results["patterns"]:
            lines.append(f"- `{p.get('id')}`: {p.get('name')} — {p.get('description')}")

    if results["discovered"]:
        lines.append(f"\n## Discovered Insights ({len(results['discovered'])} matches)")
        for d in results["discovered"]:
            lines.append(f"- `{d.get('id')}` [{d.get('status')}]: {d.get('observation')}")

    return "\n".join(lines)


# ── MCP Protocol (JSON-RPC over stdio) ─────────────────────────────

TOOLS = [
    {
        "name": "memory_status",
        "description": "Get an overview of Adaptive Flow memory state: insights count, learnings, patterns, architecture profile, current task.",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "memory_insights",
        "description": "List and filter user insights. Filter by tag, influence level (high/medium/low), or status (active/paused/retired).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "tag": {"type": "string", "description": "Filter by tag (e.g., 'testing', 'security')"},
                "influence": {"type": "string", "enum": ["high", "medium", "low"], "description": "Filter by influence level"},
                "status": {"type": "string", "enum": ["active", "paused", "retired"], "description": "Filter by status (default: active)"},
            },
        },
    },
    {
        "name": "memory_learnings",
        "description": "List and filter project learnings. Filter by type (pattern/anti-pattern/boundary), tag, or impact level.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "type": {"type": "string", "enum": ["pattern", "anti-pattern", "boundary"], "description": "Filter by learning type"},
                "tag": {"type": "string", "description": "Filter by tag"},
                "impact": {"type": "string", "enum": ["high", "medium", "low"], "description": "Filter by impact level"},
            },
        },
    },
    {
        "name": "memory_patterns",
        "description": "List and filter registered code patterns. Filter by tag.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "tag": {"type": "string", "description": "Filter by tag"},
            },
        },
    },
    {
        "name": "memory_search",
        "description": "Search across ALL memory (insights, learnings, patterns, discovered insights). Case-insensitive text search.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search query text"},
            },
            "required": ["query"],
        },
    },
]

TOOL_HANDLERS = {
    "memory_status": tool_memory_status,
    "memory_insights": tool_memory_insights,
    "memory_learnings": tool_memory_learnings,
    "memory_patterns": tool_memory_patterns,
    "memory_search": tool_memory_search,
}


def handle_request(request):
    """Process a single JSON-RPC request and return response."""
    method = request.get("method", "")
    req_id = request.get("id")
    params = request.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {
                    "name": "adaptive-flow-memory",
                    "version": "1.0.0",
                },
            },
        }

    if method == "notifications/initialized":
        return None  # No response for notifications

    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": TOOLS},
        }

    if method == "tools/call":
        tool_name = params.get("name", "")
        tool_args = params.get("arguments", {})

        handler = TOOL_HANDLERS.get(tool_name)
        if not handler:
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": f"Unknown tool: {tool_name}"}],
                    "isError": True,
                },
            }

        try:
            result_text = handler(tool_args)
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": result_text}],
                },
            }
        except Exception as e:
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": f"Error: {e}"}],
                    "isError": True,
                },
            }

    # Unknown method
    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {"code": -32601, "message": f"Method not found: {method}"},
    }


def main():
    """Run the MCP server on stdio."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
            response = handle_request(request)
            if response is not None:
                sys.stdout.write(json.dumps(response) + "\n")
                sys.stdout.flush()
        except json.JSONDecodeError:
            error_resp = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"},
            }
            sys.stdout.write(json.dumps(error_resp) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
