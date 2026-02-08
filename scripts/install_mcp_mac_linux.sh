#!/usr/bin/env bash
# Merge recommended MCP servers into user-level ~/.cursor/mcp.json
# Run from project root (or scripts/). Uses repo root as filesystem allowed path.

set -e
CURSOR_HOME="${CURSOR_USER_HOME:-$HOME/.cursor}"
MCP_JSON="$CURSOR_HOME/mcp.json"

# Project root: if run from scripts/, parent is root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/../backend" ]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  PROJECT_ROOT="$(pwd)"
fi

echo "MCP config installer (user-level)"
echo "Target: $MCP_JSON"
echo "Filesystem path: $PROJECT_ROOT"
echo ""

mkdir -p "$CURSOR_HOME"

RECOMMENDED=$(cat <<EOF
{
  "shadcn": {
    "command": "npx",
    "args": ["shadcn@latest", "mcp"]
  },
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "$PROJECT_ROOT"]
  },
  "fetch": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-fetch"]
  }
}
EOF
)

TMP_REC="$CURSOR_HOME/mcp-recommended-$$.json"
echo "$RECOMMENDED" > "$TMP_REC"
cleanup() { rm -f "$TMP_REC"; }; trap cleanup EXIT

if [ ! -f "$MCP_JSON" ]; then
  echo "$RECOMMENDED" > "$MCP_JSON"
  echo "Added: shadcn, filesystem, fetch"
else
  if command -v jq &>/dev/null; then
    # Merge: keep existing keys, add only new keys from recommended
    jq -s '.[0] as $e | .[1] | $e + (with_entries(select(.key as $k | ($e | has($k) | not))))' "$MCP_JSON" "$TMP_REC" > "$MCP_JSON.new" && mv "$MCP_JSON.new" "$MCP_JSON"
    echo "Merged recommended MCPs into existing mcp.json (new keys only)."
  elif command -v python3 &>/dev/null; then
    python3 <<PY
import json
with open("$TMP_REC") as f:
    rec = json.load(f)
try:
    with open("$MCP_JSON") as f:
        existing = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    existing = {}
for k, v in rec.items():
    if k not in existing:
        existing[k] = v
        print("Added MCP:", k)
with open("$MCP_JSON", "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
PY
  else
    cp "$MCP_JSON" "$MCP_JSON.bak"
    echo "$RECOMMENDED" > "$MCP_JSON"
    echo "Wrote recommended config (existing backed up to mcp.json.bak)."
  fi
fi

echo ""
echo "Done. Restart Cursor so it picks up MCP config."
echo "MCPs are started by Cursor automatically when you use them - no need to run anything at boot."
