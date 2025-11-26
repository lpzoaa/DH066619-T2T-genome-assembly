#!/bin/bash
#SBATCH -p xhacnormalb01
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 128

hifiasm -t 160  --telo-m AACCGAGCCCAT -l0 -o DH.HIFI `ls ~/project/onion_pangenome/rawdata/${1}/hifi/*.gz|perl -p -e "s/\n/ /g"`
