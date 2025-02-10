DOCKER        ?= $(shell which docker)
DOCKER_BUILD  ?= $(DOCKER) build --rm --progress plain --no-cache --pull

.PHONY: image
image:
	$(DOCKER_BUILD) --build-arg CHAINID=ibc0 --tag xion-chain0 .
	$(DOCKER_BUILD) --build-arg CHAINID=ibc1 --tag xion-chain1 .

.PHONY: network
network:
	$(DOCKER) compose up -d

.PHONY: network-down
network-down:
	$(DOCKER) compose down --volumes --remove-orphans
