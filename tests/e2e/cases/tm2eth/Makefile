RLY_BIN ?= ../../../../bin/yrly

.PHONY: network
network:
	$(MAKE) -C ../../chains/tendermint network
	$(MAKE) -C ../../chains/ethereum network deploy

.PHONY: network-down
network-down:
	$(MAKE) -C ../../chains/tendermint network-down
	$(MAKE) -C ../../chains/ethereum network-down

.PHONY: test
test:
	./scripts/fixture
	RLY_BIN=$(RLY_BIN) ./scripts/init-rly
	RLY_BIN=$(RLY_BIN) ./scripts/handshake
	RLY_BIN=$(RLY_BIN) ./scripts/test-tx
