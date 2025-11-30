#!/bin/bash
#SBATCH -p xhhcnormal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
minimap2 -ax map-hifi -d DH.mmi DH066619.t2t.chr.split.1000.fa

minimap2 -ax map-ont -t 120 --split-prefix ${1}_tmp DH.mmi /work/home/acn95ttd5d/project/onion_pangenome/rawdata/DH066619/DH_ul/${1}.fa.gz|samtools sort -@120 -o ${1}.ont.sorted.bam  && samtools index -@120 -c ${1}.ont.sorted.bam

minimap2 -ax map-hifi -t 120 --split-prefix ${1}_tmp DH.mmi /work/home/acn95ttd5d/project/onion_pangenome/rawdata/DH066619/hifi/${1}|samtools sort -@32 -o ${1}.hifi.sorted.bam  && samtools index -c ${1}.hifi.sorted.bam
