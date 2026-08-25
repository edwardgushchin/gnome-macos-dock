.PHONY: test test-local test-patches test-flow dry-run status

test: test-local test-patches test-flow

test-local:
	./tests/test-repository.sh

test-patches:
	./tests/test-patches.sh

test-flow:
	./tests/test-install-flow.sh

dry-run:
	./install.sh --dry-run

status:
	./status.sh
