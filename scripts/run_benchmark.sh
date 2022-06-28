#!/bin/bash

#export path
source env.sh

#get argument
cd $SPEC_PATH
source shrc
if [ $# -gt 0 ]; then
    BENCHMARK=$1
    SCHEME=$2
    CKPT_OUT_DIR=$SPEC_PATH
    
else
    echo "Using perlbench_r as default benchmark"
    BENCHMARK=perlbench_r
    SCHEME=Baseline
    CKPT_OUT_DIR=$SPEC_PATH
fi

INST_TAKE_CHECKPOINT=100000 
MAX_INSTS_CKPT= $((INST_TAKE_CHECKPOINT + 1)) 
MAX_INSTS=1000000000

#simulate on gem5

#get arguments
go $BENCHMARK
cd run/run_base_refspeed_mytest-m64.0000
cd run/run_base_refrate_mytest-m64.0000
specinvoke -n >> get.out

args=`grep "^../run_base_refrate_mytest-m64.0000/${BENCHMARK}_base.mytest-m64" get.out | cut -f 2-12 -d ' ' | cut -f 1 -d '>' | head -1` 
if [ ${#args} -gt 0 ]; then
    echo "good args"
else
    echo "bad args"
    args=`grep "^../run_base_refspeed_mytest-m64.0000/${BENCHMARK}_base.mytest-m64" get.out | cut -f 2-12 -d ' ' | cut -f 1 -d '>' | head -1`
fi

# Ckpt Dir
CKPT_OUT_DIR=$CKPT_PATH/$BENCHMARK-1-ref-x86
echo "checkpoint directory: " $CKPT_OUT_DIR
mkdir -p $CKPT_OUT_DIR

echo "option argument "
echo $args
EXE="$BENCHMARK"
for e in ../../build/build_base_mytest-m64.0000/*$BENCHMARK
do
     EXE=$e
     echo $e
done
# # checkpoint gem5 
# $GEM5_PATH/build/X86/gem5.opt \
#     $GEM5_PATH/configs/example/se.py \
#     --cmd=$EXE \
#     --options="$args"
#     --checkpoint-dir=$CKPT_OUT_DIR \
#     --take-checkpoint=$INST_TAKE_CHECKPOINT --at-instruction \
#     --mem-type=SimpleMemory \
#     --maxinsts=$MAX_INSTS_CKPT \
#     --prog-interval=0.003MHz \

# echo "Check point done"

#run gem5
 $GEM5_PATH/build/X86/gem5.opt /$GEM5_PATH/configs/example/se.py \
  -o ./ \
  --cmd=$EXE \
  --num-cpus=8 \
  --options="$args" --cpu-type TimingSimpleCPU \
    --caches --l2cache --l3cache \
    --l1d_size=32kB --l1i_size=32kB --l2_size=2MB --l3_size=16MB \
    --l1d_assoc=8  --l1i_assoc=8 --l2_assoc=8 --l3_assoc=16  \
    --mem-size=8GB --mem-type=DDR4_2400_8x8\
    --maxinsts=$MAX_INSTS \
    --fast-forward=20000000000 \
    --mirage_mode_l3=$SCHEME --l3_numSkews=4 --l3_TDR=1.50 --l3_EncrLat=3 \
    --prog-interval=300Hz 