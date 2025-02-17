GETH_HTTP_PORT ?= 8546
BEACON_HTTP_PORT ?= 19596
GETH_VERSION ?= v1.14.11
LODESTAR_VERSION ?= v1.23.0
DOCKER_COMPOSE ?= docker compose
COMPOSE_UP_OPTS ?= -d
HARDHAT ?= npx hardhat

STAKING-CLI=docker run -it --rm -v $(shell pwd)/consensus/validator_keys:/app/validator_keys ethereum/staking-deposit-cli

#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------
# Run geth lodestar deposit lodestar-validator
.PHONY:network
network:
	GETH_VERSION=$(GETH_VERSION) GETH_HTTP_PORT=$(GETH_HTTP_PORT) \
	LODESTAR_VERSION=$(LODESTAR_VERSION) BEACON_HTTP_PORT=$(BEACON_HTTP_PORT) \
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
	GETH_VERSION=$(GETH_VERSION) GETH_HTTP_PORT=$(GETH_HTTP_PORT) \
	docker compose build --no-cache geth

.PHONY:build-lodestar-image
build-lodestar-image:
	LODESTAR_VERSION=$(LODESTAR_VERSION) GETH_HTTP_PORT=$(GETH_HTTP_PORT) BEACON_HTTP_PORT=$(BEACON_HTTP_PORT) \
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
	docker run --rm ethereum/client-go:$(GETH_VERSION) --help

.PHONY:lodestar-help
lodestar-help:
	docker run --rm chainsafe/lodestar:$(LODESTAR_VERSION) --help

.PHONY:lodestar-dev-help
lodestar-dev-help:
	docker run --rm chainsafe/lodestar:$(LODESTAR_VERSION) dev --help

.PHONY:lodestar-beacon-help
lodestar-beacon-help:
	docker run --rm chainsafe/lodestar:$(LODESTAR_VERSION) beacon --help

.PHONY:lodestar-validator-help
lodestar-validator-help:
	docker run --rm chainsafe/lodestar:$(LODESTAR_VERSION) validator --help

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
	$(DOCKER_COMPOSE) run -e USE_UPGRADE_TEST=$(USE_UPGRADE_TEST) -e LCP_ENCLAVE_DEBUG=$(LCP_ENCLAVE_DEBUG) -e ZKDCAP=$(ZKDCAP) -e LCP_ZKDCAP_RISC0_MOCK=$(LCP_ZKDCAP_RISC0_MOCK) contracts $(HARDHAT) run ./scripts/deploy.js --network eth_local

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
