GETH_HTTP_PORT ?= 8546
BEACON_HTTP_PORT ?= 19596
# Glamsterdam (gloas/amsterdam) capable images.
# geth: official ethereum/client-go has no amsterdam support yet, use the ethpandaops build.
# lodestar: build of ChainSafe/lodestar unstable + the archive fix (see fix/archive-prunes-canonical-gloas-data).
GETH_IMAGE ?= ethpandaops/geth
GETH_VERSION ?= glamsterdam-devnet-8
# TEMPORARY: running the control to confirm CI really fails without the archive fix.
# chainsafe/lodestar:next is v1.47.0/6eb37b3, exactly the commit the fix branch is
# based on, so it is the fix image (v1.47.0/c270be3) minus the fix and nothing else.
# `next` is a rolling tag; it was sha256:53536243b092870262e3bd719309c9a395c345a1bff5d5e8e8a542e903ed34b5
# when this was set. Revert both lines to restore the fixed build:
#   LODESTAR_IMAGE ?= ghcr.io/yoshidan/lodestar
#   LODESTAR_VERSION ?= glamsterdam-archive-fix-c270be3e
LODESTAR_IMAGE ?= chainsafe/lodestar
LODESTAR_VERSION ?= next
DOCKER_COMPOSE ?= docker compose
COMPOSE_UP_OPTS ?= -d
# Gloas cannot be enabled at genesis: the parent block has no payload bid, so
# `prepare payload` fails and no block is ever produced. Start on fulu and fork later.
EPOCH_LATEST_HF ?= 1
HARDHAT ?= npx hardhat

STAKING-CLI=docker run -it --rm -v $(shell pwd)/consensus/validator_keys:/app/validator_keys ethereum/staking-deposit-cli

#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------
# Run geth lodestar deposit lodestar-validator
.PHONY:network
network:
	EPOCH_LATEST_HF=$(EPOCH_LATEST_HF) \
	GENESIS_TIMESTAMP=$(shell date -d'+10second' +%s 2>/dev/null || date -v+10S +%s) \
	GETH_IMAGE=$(GETH_IMAGE) GETH_VERSION=$(GETH_VERSION) GETH_HTTP_PORT=$(GETH_HTTP_PORT) \
	LODESTAR_IMAGE=$(LODESTAR_IMAGE) LODESTAR_VERSION=$(LODESTAR_VERSION) BEACON_HTTP_PORT=$(BEACON_HTTP_PORT) \
	$(DOCKER_COMPOSE) up $(COMPOSE_UP_OPTS) geth lodestar deposit lodestar-validator

.PHONY:network-down
network-down:
	docker compose down --volumes --remove-orphans

#------------------------------------------------------------------------------
# Build Docker Images
#------------------------------------------------------------------------------
.PHONY:build-images
build-images: build-geth-image build-lodestar-image build-deposit-image build-contract-image

.PHONY:build-geth-image
build-geth-image:
	GETH_IMAGE=$(GETH_IMAGE) GETH_VERSION=$(GETH_VERSION) GETH_HTTP_PORT=$(GETH_HTTP_PORT) \
	docker compose build --no-cache geth

.PHONY:build-lodestar-image
build-lodestar-image:
	LODESTAR_IMAGE=$(LODESTAR_IMAGE) LODESTAR_VERSION=$(LODESTAR_VERSION) GETH_HTTP_PORT=$(GETH_HTTP_PORT) BEACON_HTTP_PORT=$(BEACON_HTTP_PORT) \
	docker compose build --no-cache lodestar

.PHONY:build-deposit-image
build-deposit-image:
	GETH_HTTP_PORT=$(GETH_HTTP_PORT) \
	docker compose build --no-cache deposit

.PHONY:build-contract-image
build-contract-image:
	docker compose build --no-cache contracts

#------------------------------------------------------------------------------
# staking-deposit-cli / validator operation
#------------------------------------------------------------------------------
.PHONY:install-cli
install-cli:
	#./scripts/install-deposit-cli.sh
	./scripts/setup-docker-deposit-cli.sh

.PHONY:create-validator-key
create-validator-key:
	rm -rf ./consensus/validator_keys
	$(STAKING-CLI) new-mnemonic

# Note: this command is interactive
MNEMONIC=wasp pet lazy truly swim topple exile salute frozen employ aspect aim truck toward tornado afford evolve proud knife fun renew number profit cancel
#PW=password
#Validator:4
.PHONY:setup-validator-key
setup-validator-key:
	rm -rf ./consensus/validator_keys
	$(STAKING-CLI) existing-mnemonic --validator_start_index=0 --num_validators=4 --chain=localnet --eth1_withdrawal_address=0xa89F47C6b463f74d87572b058427dA0A13ec5425

.PHONY:clean-validator-key
clean-validator-key:
	rm -rf consensus/validator_keys/*.lock


#------------------------------------------------------------------------------
# Check Node Scripts
#------------------------------------------------------------------------------
.PHONY:check-block
check-block:
	GETH_HTTP_PORT=$(GETH_HTTP_PORT) BEACON_HTTP_PORT=$(BEACON_HTTP_PORT) \
	./scripts/check_block.sh

.PHONY:check-execution-block
check-execution-block:
	curl -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:$(GETH_HTTP_PORT)


#------------------------------------------------------------------------------
# Utils
#------------------------------------------------------------------------------
.PHONY:check-health-log
check-health-log:
	docker inspect --format "{{json .State.Health }}" geth | jq

.PHONY:geth-help
geth-help:
	docker run --rm $(GETH_IMAGE):$(GETH_VERSION) --help

.PHONY:lodestar-help
lodestar-help:
	docker run --rm $(LODESTAR_IMAGE):$(LODESTAR_VERSION) --help

.PHONY:lodestar-dev-help
lodestar-dev-help:
	docker run --rm $(LODESTAR_IMAGE):$(LODESTAR_VERSION) dev --help

.PHONY:lodestar-beacon-help
lodestar-beacon-help:
	docker run --rm $(LODESTAR_IMAGE):$(LODESTAR_VERSION) beacon --help

.PHONY:lodestar-validator-help
lodestar-validator-help:
	docker run --rm $(LODESTAR_IMAGE):$(LODESTAR_VERSION) validator --help

.PHONY:shfmt
shfmt:
	shfmt -l -w ./scripts/*.sh

.PHONY:shchk
shchk:
	shellcheck ./scripts/*.sh

#------------------------------------------------------------------------------
# Contract Deployment
#------------------------------------------------------------------------------
.PHONY:deploy
deploy:
	$(DOCKER_COMPOSE) run -e USE_UPGRADE_TEST=$(USE_UPGRADE_TEST) -e LCP_ENCLAVE_DEBUG=$(LCP_ENCLAVE_DEBUG) -e NO_RUN_LCP=$(NO_RUN_LCP) -e ZKDCAP=$(ZKDCAP) -e LCP_ZKDCAP_RISC0_MOCK=$(LCP_ZKDCAP_RISC0_MOCK) contracts $(HARDHAT) run ./scripts/deploy.js --network eth_local

.PHONY: dep
dep:
	$(DOCKER_COMPOSE) run contracts npm install

.PHONY: clean
clean:
	$(DOCKER_COMPOSE) run contracts sh -c '$(HARDHAT) clean && rm -rf node_modules && rm -f package-lock.json'

.PHONY: rm-oz-upgrades
rm-oz-upgrades:
	$(DOCKER_COMPOSE) run contracts sh -c 'rm -rf .openzeppelin'

.PHONY: extract-abi
extract-abi:
	./scripts/extract-abi.sh
