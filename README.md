# LG-Patch（Large Genome Patch）
[![Snakemake](https://img.shields.io/badge/Snakemake-Workflow-blue.svg)](https://snakemake.github.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview
A Snakemake-based pipeline for efficient **gap patching** in large genomes.
The workflow was developed to address the prohibitive computational cost of performing whole-genome alignments on exceptionally large genomes while reducing misalignments caused by abundant repetitive sequences.
Instead of aligning all contigs to entire chromosomes, the pipeline adopts a **contig-terminus anchoring + candidate enrichment** strategy to identify high-confidence gap-bridging contigs.

## Dependencies

The following tools are required and are assumed to be available in your environment (e.g. via `conda`, `mamba`, or system modules):

* [Snakemake](https://snakemake.readthedocs.io/) – workflow management
* [Perl](https://www.perl.org/) – used for perl scripts (e.g. candidate enrichment and AGP/PAF processing)
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
# Original chromosome-level assembly (corresponding to raw_agp)
raw_genome: "<chr.raw.fa>"
raw_agp: "<chr.raw.agp>"

# Contigs used for Round 1 (formerly utg / HiFi unitigs)
utg_ctg: "<utg.contig.fa>"

# ONT contigs used for Round 2
ont_ctg: "<ont.contig.fa>"

# PTG used in Round 1 (reference contig-level FASTA used for patching)
# This is typically the contig-level version of raw_genome; if identical, specify the same file.
ptg_round1: "<contig.raw.fa>"

# Chromosome / scaffold ID list (must match column 1 of the AGP file)
# One ID per line, e.g.:
#   Chr1
#   Chr2
#   ...
chr_list: "<chr.list>"

# Number of threads used by minimap2 / ragtag
threads: <INT>

# Threshold parameters for gap_patch_candidate_enrichment.pl
de_utg_threshold: <FLOAT>        # Default: 0.001
de_ont_threshold: <FLOAT>        # Default: 0.01
ms_threshold: <INT>              # Default: 15000
max_gap_margin: <INT>            # Default: 5000000
```

## Run
```
snakemake -s gap_patching.smk --cores 32
```

## Output
- gap-patched chromosomes  
- updated AGP  
- final merged genome  
