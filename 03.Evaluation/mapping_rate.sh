#!/bin/bash
#SBATCH -p xhacnormalb
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
samtools flagstat -@64 DH.ont.sorted.bam >DH.ont.sorted.bam.stats
samtools flagstat -@64 DH.hifi.sorted.bam >DH.hifi.sorted.bam.stats 
