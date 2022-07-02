#!/bin/bash


if [ $# -gt 0 ]; then
    BENCHMARK=$1

    
else
    echo "Using perlbench_r as default benchmark"
    BENCHMARK=perlbench_r

fi

./run_benchmark.sh $BENCHMARK Baseline 1 1.00 0 & \
./run_benchmark.sh $BENCHMARK skew-vway-rand 2 1.75 3 & \
./run_benchmark.sh $BENCHMARK skew-vway-indirect 4 1.50 3