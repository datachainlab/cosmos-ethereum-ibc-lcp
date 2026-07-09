RLY_BIN ?= ../../../../bin/yrly

.PHONY: network
network:
	$(MAKE) -C ../../chains/tendermint network
	$(MAKE) -C ../../chains/polygon network
	$(MAKE) -C ../../chains/polygon deploy extract-abi

.PHONY: network-down
network-down:
	$(MAKE) -C ../../chains/tendermint network-down
	$(MAKE) -C ../../chains/polygon network-down

.PHONY: setup
setup:
	./scripts/fixture
	./scripts/gen_rly_config.sh
	RLY_BIN=$(RLY_BIN) ./scripts/init-rly

.PHONY: handshake
handshake:
	RLY_BIN=$(RLY_BIN) ./scripts/handshake

.PHONY: test
test:
	RLY_BIN=$(RLY_BIN) ./scripts/test-tx
	RLY_BIN=$(RLY_BIN) ./scripts/test-service

.PHONY: test-operators
test-operators:
	RLY_BIN=$(RLY_BIN) ./scripts/test-operators

.PHONY: test-channel-upgrade
test-channel-upgrade:
	RLY_BIN=$(RLY_BIN) ./scripts/test-channel-upgrade

.PHONY: test-timeout
test-timeout:
	RLY_BIN=$(RLY_BIN) ./scripts/test-tx-timeout
