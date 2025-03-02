#!/bin/sh
set -eux

DOCKER=docker
RLY="${RLY_BIN} --debug"
STORE_PATH=/root/data/ibc0/`basename ${WASM_CODE}`
#TM_USER_ADDRESS=$(${RLY} tendermint keys show ibc1 testkey)
#TM_VALIDATOR_ADDRESS=$(${RLY} tendermint keys show ibc1 valkey)
TM_USER_ADDRESS=user
TM_VALIDATOR_ADDRESS=validator

${DOCKER} cp ${WASM_CODE} xion-chain0:${STORE_PATH}

${DOCKER} exec xion-chain0 \
	  xiond tx ibc-wasm store-code ${STORE_PATH} \
	  --home /root/data/ibc0 \
	  --keyring-backend test \
	  --chain-id ibc0 \
	  --title title-store-code \
	  --summary summary-store-code \
	  --from ${TM_USER_ADDRESS} \
	  --gas auto \
	  --gas-adjustment 1.1 \
	  --deposit 10000000stake \
	  --yes

sleep 2

${DOCKER} exec xion-chain0 \
	  xiond tx gov vote 1 yes \
	  --home /root/data/ibc0 \
	  --keyring-backend test \
	  --chain-id ibc0 \
	  --from ${TM_VALIDATOR_ADDRESS} \
	  --yes

# wait for voting_period to pass
sleep 10
