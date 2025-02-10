#!/bin/sh
set -eux

DOCKER=docker
RLY="${RLY_BIN} --debug"
STORE_PATH=/root/data/ibc1/`basename ${WASM_CODE}`
#TM_USER_ADDRESS=$(${RLY} tendermint keys show ibc1 testkey)
#TM_VALIDATOR_ADDRESS=$(${RLY} tendermint keys show ibc1 valkey)
TM_USER_ADDRESS=user
TM_VALIDATOR_ADDRESS=validator

${DOCKER} cp ${WASM_CODE} xion-chain1:${STORE_PATH}

${DOCKER} exec xion-chain1 \
	  xiond tx ibc-wasm store-code ${STORE_PATH} \
	  --home /root/data/ibc1 \
	  --keyring-backend test \
	  --chain-id ibc1 \
	  --title title-store-code \
	  --summary summary-store-code \
	  --from ${TM_USER_ADDRESS} \
	  --gas auto \
	  --gas-adjustment 1.1 \
	  --deposit 10000000stake \
	  --yes

sleep 2

${DOCKER} exec xion-chain1 \
	  xiond tx gov vote 1 yes \
	  --home /root/data/ibc1 \
	  --keyring-backend test \
	  --chain-id ibc1 \
	  --from ${TM_VALIDATOR_ADDRESS} \
	  --yes

# wait for voting_period to pass
sleep 10
