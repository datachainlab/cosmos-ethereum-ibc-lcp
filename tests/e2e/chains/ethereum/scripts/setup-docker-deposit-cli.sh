#!/usr/bin/env bash
set -eu

# staking-deposit-cli
#https://github.com/datachainlab/staking-deposit-cli

git clone --depth 1 -b add-dev-network https://github.com/datachainlab/staking-deposit-cli
cd staking-deposit-cli

# build docker image
make build_docker
