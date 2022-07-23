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
    L3_SKEWS=$3
    L3_TDR=$4
    L3_LAT=$5
    
else
    echo "Using perlbench_r as default benchmark"
    BENCHMARK=perlbench_r
    SCHEME=Baseline
    CKPT_OUT_DIR=$SPEC_PATH
    L3_SKEWS=2
    L3_TDR=1.75
    L3_LAT=3
fi

INST_TAKE_CHECKPOINT=100000 
#MAX_INSTS_CKPT= $((INST_TAKE_CHECKPOINT + 1)) 
MAX_INSTS=1000000000

#benchmarks

BENCHS = {perlbench_r, exchange2_r, leela_r, mcf_r, nab_r, namd_r, parest_r, povray_r, xalancbmk_s}
#simulate on gem5


#get arguments
go $BENCHMARK
cd run/run_base_refspeed_mytest-m64.0000
cd run/run_base_refrate_mytest-m64.0000
specinvoke -n >> get.out

cd ../../build/build_base_mytest-m64.0000/
for e in *$BENCHMARK
    do
        BENCHMARK=$e
        echo $e
    done
cd ../../run/run_base_refspeed_mytest-m64.0000
cd ../../run/run_base_refrate_mytest-m64.0000

args=`grep "^../run_base_refrate_mytest-m64.0000/${BENCHMARK}_base.mytest-m64" get.out | cut -f 2-12 -d ' ' | cut -f 1 -d '>' | head -1` 
if [ ${#args} -gt 0 ]; then
    echo "good args"
else
    echo "bad args"
    args=`grep "^../run_base_refspeed_mytest-m64.0000/*${BENCHMARK}_base.mytest-m64" get.out | cut -f 2-12 -d ' ' | cut -f 1 -d '>' | head -1`
fi

# Ckpt Dir
CKPT_OUT_DIR=$CKPT_PATH/$BENCHMARK-1-ref-x86
echo "checkpoint directory: " $CKPT_OUT_DIR
mkdir -p $CKPT_OUT_DIR

echo "option argument "
echo $args
EXE="$BENCHMARK"

Cactus="cactuBSSN_r"

if [[ "$BENCHMARK" == "$Cactus" ]]; then
    e=../../build/build_base_mytest-m64.0000/cactusBSSN_r
    EXE=$e
else
    echo "not equal"
    echo $BENCHMARK
    echo $Cactus
    for e in ../../build/build_base_mytest-m64.0000/*$BENCHMARK
    do
        EXE=$e
        echo $e
    done
fi
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
# BENCH2= $EXE;$EXE
# BENCH8 = $EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE
# BENCH16 = $EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE
#run gem5
OUTPUT=$HOME/output/$BENCHMARK/${SCHEME}
if [ -d "$OUTPUT" ]
then
    rm -r $OUTPUT
fi
mkdir -p $OUTPUT
chmod -R 700 $OUTPUT


 $GEM5_PATH/build/X86/gem5.opt --verbose --outdir=$OUTPUT -r -e --stdout-file=$OUTPUT/stdout.txt --stderr-file=$OUTPUT/stderr.txt\
    /$GEM5_PATH/configs/example/se.py\
    --num-cpus=16 \
    --cmd="$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE;$EXE" \
    --options="$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;$args;" \
    --cpu-type TimingSimpleCPU \
    --caches --l2cache --l3cache \
    --l1d_size=32kB --l1i_size=32kB --l2_size=256kB --l3_size=16MB \
    --l1d_assoc=8  --l1i_assoc=8 --l2_assoc=8 --l3_assoc=16  \
    --cacheline_size=64 \
    --mem-size=8GB\
    --maxinsts=$MAX_INSTS \
    --fast-forward=20000000000 \
    --warmup-insts=10000000 \
    --mirage_mode_l3=$SCHEME --l3_numSkews=$L3_SKEWS --l3_TDR=$L3_TDR --l3_EncrLat=$L3_LAT \