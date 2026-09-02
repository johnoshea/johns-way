check: lint test

test:
    tests/run.sh

lint:
    shellcheck hooks/*.sh tests/*.sh bin/*
    claude plugin validate .
