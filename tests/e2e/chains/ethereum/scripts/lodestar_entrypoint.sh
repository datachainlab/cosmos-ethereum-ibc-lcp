#!/usr/bin/env bash
set -eu

# This script is used in container of lodestar

# pwd: /usr/app

cmd="$*"
echo "command args: $cmd"

# Get genesis hash (Make sure host name of geth container)
echo "access to http://geth:${GETH_HTTP_PORT}"
genesisHash=$(curl -s http://geth:${GETH_HTTP_PORT} \
	-X POST \
	-H 'Content-Type: application/json' \
	-d '{"jsonrpc": "2.0", "id": "1", "method": "eth_getBlockByNumber","params": ["0x0", false]}' | jq -r '.result.hash')
echo "genesisHash: $genesisHash"

if [ -z "$genesisHash" ]; then
	echo "Failed to get genesisHash"
	exit 1
fi


deneb_fork_epoch=${EPOCH_DENCUN}
# Replace string of environment variable in command
tmp=$(echo $cmd | sed -e 's/\${timestamp}/'${GENESIS_TIMESTAMP}'/g')
tmp=$(echo $tmp | sed -e 's/\${genesisHash}/'${genesisHash}'/g')
cmd=$(echo $tmp | sed -e 's/\${deneb_fork_epoch}/'${deneb_fork_epoch}'/g')

echo "replaced command args: $cmd"

# Run lodestar
echo "run lodestar "
exec node ./packages/cli/bin/lodestar.js $cmd
