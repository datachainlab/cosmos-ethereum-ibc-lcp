#!/usr/bin/env bash
set -eu

GETH_HTTP_PORT=${GETH_HTTP_PORT:-8546}
BEACON_HTTP_PORT=${BEACON_HTTP_PORT:-9596}

# Get eth1 block hash, state root from latest block
block=$(curl -s http://localhost:${BEACON_HTTP_PORT}/eth/v2/beacon/blocks/head \
	-X GET -H 'Content-Type: application/json' |
	jq -r '.data.message.body.execution_payload.block_hash, .data.message.body.execution_payload.state_root')

eth1BlockHash=$(echo $block | awk '{print $1}')
stateRoot=$(echo $block | awk '{print $2}')

echo "eth1BlockHash: $eth1BlockHash"
echo "stateRoot: $stateRoot"

# Check block hash and state root are contained in execution node
block=$(curl -s -X POST \
	--data '{"jsonrpc":"2.0","method":"eth_getBlockByHash","params":["'${eth1BlockHash}'", true],"id":1}' \
	-H "Content-Type: application/json" localhost:${GETH_HTTP_PORT} |
	jq -r '.result.number, .result.stateRoot')

height=$(echo $block | awk '{print $1}')
eth1StateRoot=$(echo $block | awk '{print $2}')

echo "eth1 height: $height"
echo "eth1 eth1StateRoot: $eth1StateRoot"

if [ $stateRoot != $eth1StateRoot ]; then
	echo "stateRoot is not matched"
	exit 1
fi
