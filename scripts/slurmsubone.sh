#!/bin/bash
#
#SBATCH --account=students
#SBATCH --partition=normal
#
#SBATCH --time=120:00:00
#SBATCH --mem=32G


srun ./run_onebench.sh leela & \
./run_onebench.sh namd & \
./run_onebench.sh povray & \
./run_onebench.sh bwaves & \
./run_onebench.sh blender & \
./run_onebench.sh cactuBSSN & \
./run_onebench.sh imagick & \
./run_onebench.sh lbm & \
./run_onebench.sh xalancbmk