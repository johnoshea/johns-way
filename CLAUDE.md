# johns-way

This repository is a Claude Code plugin, and the plugin is its own marketplace. [docs/design.md](docs/design.md) is the design: the paths, the skills, the hooks, and the reasons for each. A change in behaviour updates the design, README.md, and CONTEXT.md in the same commit.

## Check

    just check

Runs shellcheck, the plugin validator, and the tests. The tests are plain bash under `tests/`: every `test_*` function in `tests/*_test.sh` runs in its own temporary directory, with `CLAUDE_PLUGIN_DATA` pointing at a fresh directory. A hook change starts with a failing test. Scripts run on macOS and Linux, so a `date` or `sed` call that differs between them carries both forms.

## Where a rule goes

Hooks hold mechanical rules. Skills hold procedures. A rule goes in the first of those that can hold it. The user's own CLAUDE.md holds the judgment rules that apply every turn.

## Skills

- Each SKILL.md is under 60 lines, routing under 40, and all of them together under 800. Files under `references/` are outside the budget and load on demand.
- Write for a reader who was not in the session: the rule, never the episode that taught it.
- Use the terms in CONTEXT.md.

## Hooks

- A hook reads its input as JSON on stdin. Exit code 2 with a message on stderr blocks the tool call and shows the message to the model. JSON on stdout with `additionalContext` adds to the model's context.
- Paths inside the plugin go through `${CLAUDE_PLUGIN_ROOT}`. State that must survive an update goes under `${CLAUDE_PLUGIN_DATA}`.
- Check the hook contract against the Claude Code docs before relying on a field or an exit code.

## Releasing

Installed copies update only when `version` in `.claude-plugin/plugin.json` changes. Bump it in the commit that finishes a change worth shipping, then tag the release with `claude plugin tag --push`.

## Development install

`just install` links this checkout into `~/.claude/skills/`, where it loads as `johns-way@skills-dir`. A machine with the marketplace copy installed keeps only one of the two enabled. Edits to a skill apply at once. Edits to hooks need `/reload-plugins`.
