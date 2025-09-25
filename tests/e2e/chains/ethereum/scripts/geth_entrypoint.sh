#!/usr/bin/env bash
set -eux

GENESIS_TIMESTAMP=${GENESIS_TIMESTAMP}

MINIMAL_SECONDS_PER_SLOT=6
MINIMAL_SLOTS_PER_EPOCH=8

FUSAKA_TIMESTAMP_DIFF=$((EPOCH_OSAKA * MINIMAL_SECONDS_PER_SLOT * MINIMAL_SLOTS_PER_EPOCH))
FUSAKA_TIMESTAMP=$((GENESIS_TIMESTAMP + FUSAKA_TIMESTAMP_DIFF))

sed -i.bak s/"\"fusakaTime\": 0/\"fusakaTime\": ${FUSAKA_TIMESTAMP}/" /execution/genesis.json

# Init
geth --datadir=/execution init --state.scheme hash --db.engine=leveldb /execution/genesis.json

# Import keys
geth --datadir=/execution account import --password /dev/null /config/dev-key0.prv
geth --datadir=/execution account import --password /dev/null /config/dev-key1.prv

geth $*
