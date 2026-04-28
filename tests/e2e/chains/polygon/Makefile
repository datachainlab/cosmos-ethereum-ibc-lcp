KURTOSIS         ?= kurtosis
KURTOSIS_ENCLAVE ?= pos
KURTOSIS_PACKAGE ?= github.com/0xPolygon/kurtosis-pos
KURTOSIS_ARGS    ?=

# Default kurtosis-pos service names — see README.md.
EL_SERVICE ?= l2-el-1-bor-heimdall-v2-validator
CL_SERVICE ?= l2-cl-1-heimdall-v2-bor-validator

EL_RPC_PORT_ID  ?= rpc   # bor JSON-RPC
CL_RPC_PORT_ID  ?= rpc   # heimdall cometbft RPC (26657)
CL_REST_PORT_ID ?= http  # heimdall cosmos REST  (1317)
CL_GRPC_PORT_ID ?= grpc  # heimdall cosmos gRPC  (3132)

.PHONY: image build-images
image build-images:
	@echo "kurtosis pulls images on demand; nothing to build."

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
