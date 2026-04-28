RLY_BIN ?= ../../../../bin/yrly

.PHONY: network
network:
	$(MAKE) -C ../../chains/polygon network

.PHONY: network-down
network-down:
	$(MAKE) -C ../../chains/polygon network-down

.PHONY: setup
setup:
	E2E_TEST_DIR=. ./scripts/gen_rly_config.sh
	RLY_BIN=$(RLY_BIN) ./scripts/init-rly

.PHONY: test
test:
	RLY_BIN=$(RLY_BIN) ./scripts/test-elc
