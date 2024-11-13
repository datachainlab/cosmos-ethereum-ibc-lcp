#!/usr/bin/env bash
set -eux

GENESIS_TIMESTAMP=${GENESIS_TIMESTAMP}
EPOCH_CANCUN=${EPOCH_DENCUN}

MINIMAL_SECONDS_PER_SLOT=6
MINIMAL_SLOTS_PER_EPOCH=8

CANCUN_TIMESTAMP_DIFF=$((EPOCH_CANCUN * MINIMAL_SECONDS_PER_SLOT * MINIMAL_SLOTS_PER_EPOCH))
CANCUN_TIMESTAMP=$((GENESIS_TIMESTAMP + CANCUN_TIMESTAMP_DIFF))

sed -i.bak s/"\"cancunTime\": 0/\"cancunTime\": ${CANCUN_TIMESTAMP}/" /execution/genesis.json

cat /execution/genesis.json

# Init
geth --datadir=/execution init --state.scheme hash --db.engine=leveldb /execution/genesis.json

# Import keys
geth --datadir=/execution account import --password /dev/null /config/dev-key0.prv
geth --datadir=/execution account import --password /dev/null /config/dev-key1.prv

geth $*
