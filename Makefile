SHELL := /usr/bin/env bash

.PHONY: validate sync shellcheck test

validate:
	./scripts/validate-repo.sh

sync:
	./scripts/sync-template-assets.sh

shellcheck:
	shellcheck -x scripts/*.sh templates/*/.devcontainer/*.sh tests/*.sh

test:
	./tests/run-tests.sh
