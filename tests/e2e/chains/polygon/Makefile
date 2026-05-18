KURTOSIS         ?= kurtosis
KURTOSIS_ENCLAVE ?= pos
# Pin to a commit on main that has `el_bor_archive_mode=True` by default for the
# 1-validator devnet (commit e3d4d1d, "align devnet config with amoy", #560).
# We need archive mode because the polygon prover calls `eth_getProof` against
# historical bor blocks tied to Heimdall milestones — a non-archive validator
# only retains state for ~1024 blocks and the prover then hits "historical state
# is not available". The trade-off is that this commit isn't tagged and the
# service names gain a `-archive` suffix (reflected in EL_SERVICE / CL_SERVICE).
KURTOSIS_VERSION ?= 97722d0a6dd8ebf2ca0a18b760fda45cc067336b
KURTOSIS_PACKAGE ?= github.com/0xPolygon/kurtosis-pos@$(KURTOSIS_VERSION)
KURTOSIS_ARGS    ?=

# Default kurtosis-pos service names — see README.md.
EL_SERVICE ?= l2-el-1-bor-heimdall-v2-validator-archive
CL_SERVICE ?= l2-cl-1-heimdall-v2-bor-validator-archive

EL_RPC_PORT_ID  ?= rpc   # bor JSON-RPC
CL_RPC_PORT_ID  ?= rpc   # heimdall cometbft RPC (26657)
CL_REST_PORT_ID ?= http  # heimdall cosmos REST  (1317)
CL_GRPC_PORT_ID ?= grpc  # heimdall cosmos gRPC  (3132)

DOCKER_COMPOSE ?= docker compose
HARDHAT        ?= npx hardhat

.PHONY: image build-images
image: build-images
build-images:
	$(DOCKER_COMPOSE) build --no-cache contracts

.PHONY: dep
dep:
	$(DOCKER_COMPOSE) run --rm contracts npm install

.PHONY: deploy
deploy:
	BOR_RPC_URL=$$($(MAKE) -s bor-rpc-url) \
	$(DOCKER_COMPOSE) run --rm contracts $(HARDHAT) run ./scripts/deploy.js --network bor_local

.PHONY: extract-abi
extract-abi:
	./scripts/extract-abi.sh

.PHONY: rm-oz-upgrades
rm-oz-upgrades:
	$(DOCKER_COMPOSE) run --rm contracts sh -c 'rm -rf .openzeppelin'

.PHONY: clean-contracts
clean-contracts:
	$(DOCKER_COMPOSE) run --rm contracts sh -c '$(HARDHAT) clean && rm -rf node_modules && rm -f package-lock.json'

.PHONY: network
network:
	$(KURTOSIS) run --enclave $(KURTOSIS_ENCLAVE) $(KURTOSIS_PACKAGE) $(KURTOSIS_ARGS)

.PHONY: network-down
network-down:
	$(KURTOSIS) enclave rm --force $(KURTOSIS_ENCLAVE) || true

.PHONY: bor-rpc-url heimdall-cometbft-url heimdall-rest-url heimdall-grpc-url
bor-rpc-url:
	@$(KURTOSIS) port print $(KURTOSIS_ENCLAVE) $(EL_SERVICE) $(EL_RPC_PORT_ID)

heimdall-cometbft-url:
	@$(KURTOSIS) port print $(KURTOSIS_ENCLAVE) $(CL_SERVICE) $(CL_RPC_PORT_ID)

heimdall-rest-url:
	@$(KURTOSIS) port print $(KURTOSIS_ENCLAVE) $(CL_SERVICE) $(CL_REST_PORT_ID)

heimdall-grpc-url:
	@$(KURTOSIS) port print $(KURTOSIS_ENCLAVE) $(CL_SERVICE) $(CL_GRPC_PORT_ID)

.PHONY: endpoints
endpoints:
	@printf 'BOR_ENDPOINT=%s\n'                $$($(MAKE) -s bor-rpc-url)
	@printf 'HEIMDALL_COMETBFT_ENDPOINT=%s\n'  $$($(MAKE) -s heimdall-cometbft-url)
	@printf 'HEIMDALL_COSMOS_ENDPOINT=%s\n'    $$($(MAKE) -s heimdall-rest-url)

.PHONY: inspect
inspect:
	$(KURTOSIS) enclave inspect $(KURTOSIS_ENCLAVE)
