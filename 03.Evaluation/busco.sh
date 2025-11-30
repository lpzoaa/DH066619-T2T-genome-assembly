#!/bin/bash
#SBATCH -p xhhcnormal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
source activate
conda activate compleasm

compleasm run -t48 -l embryophyta_odb10 -a ${1}.chr.fa -o ${1}.chr.busco
