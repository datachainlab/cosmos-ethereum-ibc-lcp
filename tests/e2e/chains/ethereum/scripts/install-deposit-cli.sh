#!/usr/bin/env bash
set -eu

# staking-deposit-cli
# https://github.com/ethereum/staking-deposit-cli/releases

BASE_URL=https://github.com/ethereum/staking-deposit-cli/releases/download/v2.3.0/
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
BIN_DIR=${SCRIPT_DIR}/../bin
mkdir -p $BIN_DIR

OS="$(uname)"
file=""
if [[ "$OS" =~ ^Darwin ]]; then
	file=staking_deposit-cli-76ed782-darwin-amd64
elif [[ "$OS" =~ ^Linux ]]; then
	file=staking_deposit-cli-76ed782-linux-amd64
else
	echo "This platform is not supported"
	exit 1
fi

# download
curl -LO ${BASE_URL}${file}.tar.gz

tar -zxvf ${file}.tar.gz
mv ${file}/deposit ${BIN_DIR}/

# clean
rm -rf ${file} ${file}.tar.gz
