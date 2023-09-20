DOCKER        ?= $(shell which docker)
DOCKER_BUILD  ?= $(DOCKER) build --rm --no-cache --pull

protoVer=0.13.1
protoImageName=ghcr.io/cosmos/proto-builder:$(protoVer)
protoImage=$(DOCKER) run --user 0 --rm -v $(CURDIR):/workspace --workdir /workspace $(protoImageName)

.PHONY: image
image:
	$(DOCKER_BUILD) --build-arg CHAINID=ibc0 --tag tendermint-chain .

.PHONY: proto-gen
proto-gen:
	@echo "Generating Protobuf files"
	@$(protoImage) sh ./scripts/protocgen.sh

.PHONY: proto-update-deps
proto-update-deps:
	@echo "Updating Protobuf dependencies"
	$(DOCKER) run --user 0 --rm -v $(CURDIR)/proto:/workspace --workdir /workspace $(protoImageName) buf mod update

.PHONY: network
network:
	$(DOCKER) compose up -d

.PHONY: network-down
network-down:
	$(DOCKER) compose down --volumes --remove-orphans
