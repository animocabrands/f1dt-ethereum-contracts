#!/bin/bash

contractsList=['REVV.sol','DeltaTimeStakingBeta.sol']

inputFolder='contracts/'
outputFolder='contracts_flattened/'

if [ ! -f $contractsList ]
then
    echo "${contractsList} is missing"
    exit 0
fi

for contract in `cat $contractsList`
do
    path=`dirname $contract`
    inputPath=${inputFolder}${path}
    outputPath=${outputFolder}${path}
    mkdir -p $outputPath
    truffle-flattener ${inputFolder}${contract} > ${outputFolder}${contract}
done