#!/bin/sh
set -x

xiond --home ${CHAINDIR}/${CHAINID} start --pruning=nothing
