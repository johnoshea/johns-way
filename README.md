# johns-way

A Claude Code plugin holding the skills and hooks for how I work. The design, including the paths every request is routed through and the build order, is in [docs/design.md](docs/design.md).

## Install

Claude Code loads any folder under `~/.claude/skills/` that has a `.claude-plugin/plugin.json` as a plugin, with no install step. Link this repository there:

```
ln -s "$PWD" ~/.claude/skills/johns-way
```

The plugin is then named `johns-way@skills-dir` and its skills are `/johns-way:<skill>`. Edits to a skill apply at once. Edits to hooks need `/reload-plugins` or a new session.

To test changes without linking, start Claude Code with `claude --plugin-dir .`.

## Check

```
just check
```

Runs shellcheck over the hooks and tests, the plugin validator, and the tests under `tests/`. The tests are plain bash: every function named `test_*` in `tests/*_test.sh` runs in its own temporary directory.

## Layout

```
.claude-plugin/plugin.json   manifest
skills/<name>/SKILL.md       one skill per folder
hooks/hooks.json             hook registrations
hooks/*.sh                   hook scripts
tests/                       test runner, helpers, and tests
docs/design.md               the design
```

`claude_desktop_suggested_skills/` holds earlier drafts kept for reference only.
