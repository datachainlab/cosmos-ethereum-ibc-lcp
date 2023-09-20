#!/usr/bin/env bash

set -eo pipefail

echo "Generating gogo proto code"
cd proto

buf generate --template buf.gen.gogo.yaml $file

cd ..

# move proto files to the right places
cp -r github.com/datachainlab/cosmos-ethereum-ibc-lcp/tests/e2e/chains/tendermint/* ./
rm -rf github.com

go mod tidy
