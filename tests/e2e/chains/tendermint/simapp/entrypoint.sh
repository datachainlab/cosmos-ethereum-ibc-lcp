#!/bin/sh
set -x

if [ -z "$IBC_AUTHORITY" ]
then
    export IBC_AUTHORITY=`jq -r .address ${CHAINDIR}/${CHAINID}/key_seed.json`
else
    unset IBC_AUTHORITY
fi

simd --home ${CHAINDIR}/${CHAINID} start --pruning=nothing
