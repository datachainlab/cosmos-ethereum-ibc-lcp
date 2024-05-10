#!/bin/sh

cd "`dirname $0`"/..
ARTIFACTS=contracts/artifacts
ABIS=contracts/abis

mkdir -p $ABIS

for f in `find $ARTIFACTS -type d -name '*.sol'`
do
    contract=`basename $f | sed s/\.sol$//`
    jsonfile=$f/$contract.json
    if [ -e $jsonfile ]
    then
	abifile=`echo $f | sed "s#^$ARTIFACTS#$ABIS#" | sed s/\.sol$/.json/`
	mkdir -p `dirname $abifile`
	jq .abi $jsonfile > $abifile
    fi
done
