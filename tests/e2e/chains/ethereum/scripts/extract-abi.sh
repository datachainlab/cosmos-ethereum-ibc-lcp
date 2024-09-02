#!/bin/sh

cd "`dirname $0`"/..
ARTIFACTS=contracts/artifacts
ABIS=contracts/abis

mkdir -p $ABIS

for soldir in `find $ARTIFACTS -type d -name '*.sol'`
do
    for jsonfile in `find $soldir -type f -name '*.json' ! -name '*.dbg.json'`
    do
	abifile=`echo $jsonfile | sed "s#^$ARTIFACTS#$ABIS#"`
	mkdir -p `dirname $abifile`
	jq .abi $jsonfile > $abifile
    done
done
