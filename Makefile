# Makefile — build, check, test. The three targets the README names;
# the equivalent direct commands are listed there under Usage.
#
#   make check SWIPL=/path/to/swipl   overrides the Prolog used

SWIPL ?= swipl

.PHONY: build check test

build:
	$(SWIPL) -q -g build -t halt build.pl

check:
	$(SWIPL) -q -g check -t halt build.pl

test:
	$(SWIPL) -q -s tests.pl -g run_tests -t halt
