#!/usr/bin/env bash
# The check every commit must pass, run in directory $1: the dependency
# cooldown, then the project's check target. The commit hook and the
# repository pre-commit hook installed by johns-way-install-pre-commit both
# call this script.
#
# The check target is `just check` when the justfile has a check recipe.
# Otherwise, a Python project runs its tests and lint through uv. A repository
# with neither has nothing to run and passes.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
cd "${1:-.}"

"$script_dir/cooldown-check.sh" "$PWD"

if just --summary 2>/dev/null | tr ' ' '\n' | grep -qx check; then
    just check
elif [ -f pyproject.toml ]; then
    uv run pytest -q
    uv run ruff check .
fi
