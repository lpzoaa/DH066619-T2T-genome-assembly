# LG-Patch（Large Genome Patch）
[![Snakemake](https://img.shields.io/badge/Snakemake-Workflow-blue.svg)](https://snakemake.github.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview
A Snakemake-based pipeline for efficient **gap patching** in large genomes.
The workflow was developed to address the prohibitive computational cost of performing whole-genome alignments on exceptionally large genomes while reducing misalignments caused by abundant repetitive sequences.
Instead of aligning all contigs to entire chromosomes, the pipeline adopts a **contig-terminus anchoring + candidate enrichment** strategy to identify high-confidence gap-bridging contigs.

### <a name="Dependencies"></a>Dependencies

The following tools are required and are assumed to be available in your environment (e.g. via `conda`, `mamba`, or system modules):

* [Snakemake](https://snakemake.readthedocs.io/) – workflow management
* [Perl](https://www.perl.org/) – used for helper scripts (e.g. candidate enrichment and AGP/PAF processing)
* [minimap2](https://github.com/lh3/minimap2) – long-read and contig-to-contig alignment
* [RagTag](https://github.com/malonge/RagTag) – homology-based assembly patching
* [seqkit](https://github.com/shenwei356/seqkit) – FASTA/FASTQ manipulation
* [samtools](http://www.htslib.org/) – BAM/CRAM/SAM utilities

## Installation
Clone repository:
```
git clone https://github.com/lpzoaa/DH066619-T2T-genome-assembly.git
cd DH066619-T2T-genome-assembly
```

## Configuration
Edit `config.yaml`:
```
raw_genome: "DH066619_2.FINAL.split.fa"
chr_list: "chr.list"
threads: 32
de_utg_threshold: 0.001
de_ont_threshold: 0.01
```

## Run
```
snakemake -s gap_patching.smk --cores 32
```

## Output
- gap-patched chromosomes  
- updated AGP  
- final merged genome  
