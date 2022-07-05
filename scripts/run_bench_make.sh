#!/bin/bash

#export path
source env.sh
cd $GEM5_PATH
cd scripts



cd $SPEC_PATH
source shrc
echo $#
if [ $# -gt 0 ]; then
    BENCHMARK=$1
else
    echo "Using perlbench_r as default benchmark"
    BENCHMARK=perlbench_r
fi

MAX_INSTS=1000000000

#remove and make a new build
go $BENCHMARK
rm -r build
runcpu --fake --config myconfig1 $BENCHMARK

#compile the program
cd build/build_base_mytest-m64.0000
specmake
specmake TARGET=$BENCHMARK




