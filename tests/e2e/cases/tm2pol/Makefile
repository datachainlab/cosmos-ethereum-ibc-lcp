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
