#!/bin/bash
#SBATCH -p xhacnormalb
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 24
pandepth -i DH.ont.sorted.bam -w 50000 -t 32 -o DH.ont.sorted.50k
pandepth -i DH.hifi.sorted.bam -w 50000 -t 32 -o DH.hifi.sorted.50k
