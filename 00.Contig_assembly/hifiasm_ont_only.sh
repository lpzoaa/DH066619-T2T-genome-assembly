#!/bin/bash
#SBATCH -p xhhcnormal01
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 48
hifiasm -t64 -l0 --ont -o DH.ONT `ls ~/project/onion_pangenome/rawdata/DH066619/DH_ul/*.fq.gz|perl -p -e "s/\n/ /g"`
