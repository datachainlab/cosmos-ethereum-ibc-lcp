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

# Get timestamp
# Note: alpine has a problem for date command, `coreutils`` is required
#  - https://unix.stackexchange.com/questions/206540/date-d-command-fails-on-docker-alpine-linux-container
OS="$(uname)"
timestamp=""
if [[ "$OS" =~ ^Darwin ]]; then
	timestamp=$(date -v+10S '+%s')
elif [[ "$OS" =~ ^Linux ]]; then
	timestamp=$(date -d'+10second' +%s)
else
	echo "This platform is not supported"
	exit 1
fi

# Replace string of environment variable in command
tmp=$(echo $cmd | sed -e 's/\${timestamp}/'${timestamp}'/g')
tmp=$(echo $tmp | sed -e 's/\${genesisHash}/'${genesisHash}'/g')
tmp=$(echo $tmp | sed -e 's/\${GETH_HTTP_PORT}/'${GETH_HTTP_PORT}'/g')
cmd=$(echo $tmp | sed -e 's/\${BEACON_HTTP_PORT}/'${BEACON_HTTP_PORT}'/g')

echo "replaced command args: $cmd"

# Run lodestar
echo "run lodestar "
exec node ./packages/cli/bin/lodestar.js $cmd
