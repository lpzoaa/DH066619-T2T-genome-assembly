#!/bin/bash
#SBATCH -p xhacnormala01
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
source activate
conda activate merqury

cd $1

meryl k=21 count output ${1}.meryl [`ls ~/project/onion_pangenome/rawdata/${1}/hifi/*.gz|perl -p -e "s/\n/ /g"`]

merqury.sh ${1}.meryl ${1}.chr.fa ${1}
