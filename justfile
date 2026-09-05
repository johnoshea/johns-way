check: lint test

# Install the checkout for both hosts; rerun after edits for Codex.
install: install-claude install-codex

install-claude:
    mkdir -p ~/.claude/skills
    ln -sfn "{{justfile_directory()}}" ~/.claude/skills/johns-way

install-codex:
    bin/johns-way-install-codex

test:
    tests/run.sh

lint:
    shellcheck hooks/*.sh tests/*.sh bin/*
    claude plugin validate .
