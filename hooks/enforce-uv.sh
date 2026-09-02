#!/usr/bin/env bash
set -euo pipefail

CMD=$(jq -r '.tool_input.command // ""')

block() {
    cat >&2 <<EOF
Blocked by uv-enforcement hook: $1

This project uses uv. Use:
  uv run python ...      (NOT python / python3)
  uv add <pkg>           (NOT pip install / uv pip install)
  uv run <tool> ...      (NOT direct venv binary invocation)
  uv tree                (NOT uv pip list)

See CLAUDE.md.
EOF
    exit 2
}

# Bare python/python3 at command position (start, or after ; && || |)
# Allows "uv run python ..." because python is then preceded by a space, not a separator.
if echo "$CMD" | grep -qE '(^|[;&|])[[:space:]]*python3?([[:space:]]|$)'; then
    block "direct python/python3 invocation"
fi

# Any pip subcommand — catches `pip install`, `pip3 install`, `uv pip install`, etc.
if echo "$CMD" | grep -qE '\bpip3?[[:space:]]+(install|uninstall|sync|freeze|list|show)\b'; then
    block "direct pip invocation"
fi

exit 0
