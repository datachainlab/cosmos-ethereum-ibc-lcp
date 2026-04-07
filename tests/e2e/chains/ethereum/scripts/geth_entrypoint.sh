#!/usr/bin/env bash
set -eux

GENESIS_TIMESTAMP=${GENESIS_TIMESTAMP}
EPOCH_LATEST_HF=${EPOCH_LATEST_HF}

MINIMAL_SECONDS_PER_SLOT=6
MINIMAL_SLOTS_PER_EPOCH=8

# Set latest hard fork timestamp based on EPOCH_LATEST_HF
# Currently: osakaTime for Fulu/Osaka (update when new HF is added)
# When EPOCH_LATEST_HF=0, keep timestamp=0 (from genesis)
# Otherwise, set to future timestamp
if [ "$EPOCH_LATEST_HF" -gt 0 ]; then
    LATEST_HF_TIMESTAMP_DIFF=$((EPOCH_LATEST_HF * MINIMAL_SECONDS_PER_SLOT * MINIMAL_SLOTS_PER_EPOCH))
    LATEST_HF_TIMESTAMP=$((GENESIS_TIMESTAMP + LATEST_HF_TIMESTAMP_DIFF))
    sed -i.bak s/"\"osakaTime\": 0/\"osakaTime\": ${LATEST_HF_TIMESTAMP}/" /execution/genesis.json
fi

# Init
geth --datadir=/execution init --state.scheme hash --db.engine=leveldb /execution/genesis.json

# Import keys
geth --datadir=/execution account import --password /dev/null /config/dev-key0.prv
geth --datadir=/execution account import --password /dev/null /config/dev-key1.prv

geth $*
