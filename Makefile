SWIPL ?= swipl
NODE  ?= node

.PHONY: build check test test-prolog test-html

build:
	$(SWIPL) -q -g build -t halt build.pl

check:
	$(SWIPL) -q -g check -t halt build.pl
	$(NODE) tools/check-html.mjs

test: test-prolog test-html

test-prolog:
	$(SWIPL) -q -s tests.pl -g run_tests -t halt

test-html:
	$(NODE) tools/check-html.mjs
