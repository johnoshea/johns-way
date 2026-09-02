check: lint test

# Link this repository into ~/.claude/skills so Claude Code loads it as johns-way@skills-dir.
install:
    ln -sfn "{{justfile_directory()}}" ~/.claude/skills/johns-way

test:
    tests/run.sh

lint:
    shellcheck hooks/*.sh tests/*.sh bin/*
    claude plugin validate .
