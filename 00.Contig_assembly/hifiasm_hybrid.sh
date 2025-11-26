#!/bin/bash
#SBATCH -p xhhcnormal01
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64

hifiasm -t 64 --telo-m AACCGAGCCCAT -o DH.hybrid -l0 --ul `ls ~/project/onion_pangenome/rawdata/DH066619/DH_ul/*.fa.gz|perl -p -e "s/\n/,/g"|perl -p -e "s/\,$//"` `ls ~/project/onion_pangenome/rawdata/DH066619/hifi/*.gz|perl -p -e "s/\n/ /g"`
