#!/bin/bash
#	
#SBATCH --cpus-per-task=16
#SBATCH --time=36:00:00
#SBATCH --mem=64G

srun ./run_onebench_all.sh ALL