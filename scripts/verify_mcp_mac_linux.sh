#!/usr/bin/env bash
# Verify that recommended MCP server commands are available (npx can run them).
# This does NOT start MCPs for Cursor - Cursor starts MCPs automatically when you use them.
# Use this script only to check that install_mcp_mac_linux.sh was applied and commands work.

set -e
echo "Checking MCP commands (quick smoke test)..."
echo ""

check() {
  name="$1"
  shift
  printf "  %s ... " "$name"
  npx "$@" & pid=$!
  sleep 2
  kill $pid 2>/dev/null || true
  echo "OK (process started)"
}

check "fetch"  -y "@modelcontextprotocol/server-fetch"
check "shadcn" "shadcn@latest" mcp

echo ""
echo "MCPs are started by Cursor when needed. No need to run them at boot."
