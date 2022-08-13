#!/bin/bash
#
#SBATCH --account=students
#SBATCH --partition=normal
#
#SBATCH --cpus-per-task=3
#SBATCH --time=120:00:00
#SBATCH --mem=32G

srun ./run_onebench_all.sh ALL

# srun ./run_onebench_all.sh perlbench &
# ./run_onebench_all.sh gcc &
# ./run_onebench_all.sh leela &
# ./run_onebench_all.sh mcf &
# ./run_onebench_all.sh namd &
# ./run_onebench_all.sh povray &
# ./run_onebench_all.sh xz &
# ./run_onebench_all.sh bwaves &
# ./run_onebench_all.sh blender &
# ./run_onebench_all.sh cactuBSSN &
# ./run_onebench_all.sh deepsjeng &
# ./run_onebench_all.sh imagick &
# ./run_onebench_all.sh lbm &
# ./run_onebench_all.sh xalancbmk