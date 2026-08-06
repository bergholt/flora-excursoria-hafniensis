SWIPL ?= swipl

.PHONY: build check test

build:
	$(SWIPL) -q -g build -t halt build.pl

check:
	$(SWIPL) -q -g check -t halt build.pl

test:
	$(SWIPL) -q -s tests.pl -g run_tests -t halt
