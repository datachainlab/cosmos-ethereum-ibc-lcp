#!/usr/bin/env bash
set -eux

GENESIS_TIMESTAMP=${GENESIS_TIMESTAMP}
EPOCH_PRAGUE=${EPOCH_PECTRA}

MINIMAL_SECONDS_PER_SLOT=6
MINIMAL_SLOTS_PER_EPOCH=8

PRAGUE_TIMESTAMP_DIFF=$((EPOCH_PRAGUE * MINIMAL_SECONDS_PER_SLOT * MINIMAL_SLOTS_PER_EPOCH))
PRAGUE_TIMESTAMP=$((GENESIS_TIMESTAMP + PRAGUE_TIMESTAMP_DIFF))

sed -i.bak s/"\"pragueTime\": 0/\"pragueTime\": ${PRAGUE_TIMESTAMP}/" /execution/genesis.json

# Init
geth --datadir=/execution init --state.scheme hash --db.engine=leveldb /execution/genesis.json

# Import keys
geth --datadir=/execution account import --password /dev/null /config/dev-key0.prv
geth --datadir=/execution account import --password /dev/null /config/dev-key1.prv

geth $*
