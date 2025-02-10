RLY_BIN ?= ../../../../bin/yrly

.PHONY: network
network:
	$(MAKE) -C ../../chains/xion network
	sleep 1

.PHONY: network-down
network-down:
	$(MAKE) -C ../../chains/xion network-down

.PHONY: setup
setup:
	./scripts/fixture
	RLY_BIN=$(RLY_BIN) ./scripts/init-rly

.PHONY: handshake
handshake:
	RLY_BIN=$(RLY_BIN) ./scripts/handshake

.PHONY: test-channel-upgrade
test-channel-upgrade:
	RLY_BIN=$(RLY_BIN) ./scripts/test-channel-upgrade

.PHONY: test
test:
	RLY_BIN=$(RLY_BIN) ./scripts/test-tx

.PHONY: restore
restore:
	RLY_BIN=$(RLY_BIN) ./scripts/restore

.PHONY: test-operators
test-operators:
	RLY_BIN=$(RLY_BIN) ./scripts/test-operators
