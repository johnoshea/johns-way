# johns-way

This repository is a Claude Code and Codex plugin, and the plugin is its own marketplace. [docs/design.md](docs/design.md) is the design: the paths, the skills, the hooks, and the reasons for each. When you change behaviour, update the design, README.md, and CONTEXT.md in the same commit.

## Check

    just check

Runs shellcheck, the plugin validator, and the tests. The tests are plain bash under `tests/`: every `test_*` function in `tests/*_test.sh` runs in its own temporary directory, with `CLAUDE_PLUGIN_DATA` pointing at a fresh directory. Start each hook change with a failing test. Scripts run on macOS and Linux, so include both forms of any `date` or `sed` call that differs between them.

## Where a rule goes

Hooks contain mechanical rules. Skills contain procedures. Put a rule in the first of those that can contain it. The user's own CLAUDE.md contains the judgment rules that apply every turn.

## Skills

- Each SKILL.md is under 60 lines, routing under 40, and all of them together under 800. Files under `references/` are outside the budget and load on demand.
- Write for a reader who was not in the session: the rule, never the story of how we arrived at it.
- Use the terms in CONTEXT.md.

## Hooks

- A hook reads its input as JSON on stdin. When a hook exits with code 2, Claude Code blocks the tool call and shows the stderr message to the model. When a hook prints JSON with `additionalContext` on stdout, Claude Code adds it to the model's context.
- Build paths inside the plugin from `${CLAUDE_PLUGIN_ROOT}`. Store state that must be kept after an update under `${CLAUDE_PLUGIN_DATA}`.
- Check the hook contract against the Claude Code docs before relying on a field or an exit code.

## Releasing

Installed copies are updated only when `version` in `.claude-plugin/plugin.json` changes. Bump it in the commit that finishes a change worth shipping, then tag the release with `claude plugin tag --push`.

## Development install

`just install` links this checkout into `~/.claude/skills/`, where Claude Code loads it as `johns-way@skills-dir`. On a machine with the marketplace copy installed, enable only one of the two. Edits to a skill are live at once. After edits to hooks, run `/reload-plugins`.

Codex uses `.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`. `just install` also runs `just install-codex`, which refreshes a generated copy under `.local/codex/` and reinstalls it with a cache suffix. `just install-claude` installs only Claude Code. After a reinstall, start a new Codex thread and trust the hooks explicitly through `/hooks`. Release versions are maintained in both manifests.
