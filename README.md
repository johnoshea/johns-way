# johns-way

A Claude Code plugin holding the skills and hooks for how I work. The design, including the paths every request is routed through and the build order, is in [docs/design.md](docs/design.md).

## Install

Claude Code loads any folder under `~/.claude/skills/` that has a `.claude-plugin/plugin.json` as a plugin, with no install step. Link this repository there:

```
just install
```

The plugin's hooks replace any copies of the same hooks in `~/.claude/settings.json`; remove those entries so that only one copy fires.

The plugin is then named `johns-way@skills-dir` and its skills are `/johns-way:<skill>`. Edits to a skill apply at once. Edits to hooks need `/reload-plugins` or a new session.

To test changes without linking, start Claude Code with `claude --plugin-dir .`.

## Hooks

| Hook | Event | What it does |
| --- | --- | --- |
| session-start | SessionStart | Injects the routing skill, reports specs with unfinished tasks and uncommitted changes, records the start time |
| commit-check | PreToolUse on Bash | Before `git commit`: the dependency cooldown, then `just check`. Blocks `--no-verify` |
| check-in | PostToolUse | Once per session after `JOHNS_WAY_CHECKIN_MINUTES` (60), asks whether medium work should upgrade |
| enforce-uv | PreToolUse on Bash | Blocks direct python and pip in favour of uv |
| ask-dont-announce | Stop | Blocks a turn that announces a decision instead of asking |

`johns-way-install-pre-commit` puts the same commit check into a repository's git pre-commit hook. `johns-way-release-date` prints when a package version or Action ref was released.

## Check

```
just check
```

Runs shellcheck over the hooks, tests, and `bin/`, the plugin validator, and the tests under `tests/`. The tests are plain bash: every function named `test_*` in `tests/*_test.sh` runs in its own temporary directory.

## Layout

```
.claude-plugin/plugin.json   manifest
skills/<name>/SKILL.md       one skill per folder
skills/<name>/references/    reference material a review skill loads on demand
hooks/hooks.json             hook registrations
hooks/*.sh                   hook scripts
agents/<name>.md             subagent definitions, referenced as johns-way:<name>
bin/                         executables on the Bash PATH while the plugin is enabled
tests/                       test runner, helpers, and tests
docs/design.md               the design
```

`claude_desktop_suggested_skills/` holds earlier drafts kept for reference only.
