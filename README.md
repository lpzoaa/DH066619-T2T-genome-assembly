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
# Add utility scripts to PATH
export PATH=./utils:${PATH}

# Create log directory
mkdir -p logs

# Execute Snakemake workflow on SLURM cluster
~/anaconda3/bin/snakemake \
    --snakefile gap_patching.smk \
    --configfile config.yaml \
    --jobs 40 \
    --cluster-config cluster.yaml \
    --keep-going \
    --cluster "sbatch -p {cluster.queue} -c {cluster.nCPUs} -n 1 -N 1 -o {cluster.output} -e {cluster.error}" 
```

## Notes

- The workflow relies on a cluster scheduling system (e.g., SLURM, SGE, LSF, PBS).
- The example run command uses **SLURM** via `sbatch`. If your computing environment uses a different scheduler, you must modify:
  1. **`cluster.yaml`** — update keys such as `queue`, `nCPUs`, `output`, and `error` to match your system.
  2. **`--cluster` submission string** — replace the SLURM command  
     ```
     sbatch -p {cluster.queue} -c {cluster.nCPUs} -n 1 -N 1 -o {cluster.output} -e {cluster.error}
     ```
     with the correct submission command for your scheduler:
     - **PBS/Torque**: `qsub -q {cluster.queue} -l nodes=1:ppn={cluster.nCPUs}`
     - **SGE**: `qsub -q {cluster.queue} -pe smp {cluster.nCPUs}`
     - **LSF**: `bsub -q {cluster.queue} -n {cluster.nCPUs}`

- Before launching full jobs, it is recommended to run:
  ```
  snakemake --snakefile gap_patching.smk --configfile config.yaml -np
  ```
  to check rule dependencies and confirm cluster settings.

## Output
- gap-patched chromosomes  
- updated AGP  
- final merged genome
# LG-Patch: One-round manual gap patching (no Snakemake)

This document explains how to run **one round** of the LG-Patch gap-patching workflow **step by step on the command line**, without using Snakemake.

For additional rounds, simply treat the patched assembly (AGP + FASTA) from the previous round as the new input assembly and repeat the procedure with a new set of patching contigs.

---

## 1. Required inputs

Assume you have the following files (names adapted from `config.yaml`):

- **Scaffold-level assembly**
  - `raw_genome` — scaffold-level FASTA (e.g. `DH066619_2.FINAL.split.fa`)
  - `raw_agp` — corresponding AGP (e.g. `DH066619_2.FINAL.agp`)

- **Patching contigs for this round**
  - `ctg.fa` — contigs used to patch gaps  
    - In the original onion workflow:  
      - Round 1: HiFi/ONT hybrid unitigs (`utg_ctg`)  
      - Round 2: ONT-only contigs (`ont_ctg`)

- **Per-chromosome information**
  - `chr.list` — one chromosome/scaffold ID per line (must match column 1 of `raw_agp`), e.g.
    ```text
    Chr1
    Chr2
    ...
    ```

- **Utilities (in `./utils/`)**
  - `split_scaffold_by_agp.pl`
  - `gap_patch_candidate_enrichment.pl`
  - `filter_paf_by_de.pl`
  - `collapse_chr_from_agp.pl`

Make sure `./utils` is on your `PATH`:

```bash
export PATH=./utils:${PATH}
```

Create a working directory for this round (here we use `round1`):

```bash
mkdir -p round1/ref round1/ctg round1/maps round1/candidates round1/ragtag
```

---

## 2. Split the scaffold assembly into per-chromosome contig FASTA + AGP

For each chromosome ID in `chr.list`, split the scaffold-level assembly into contig-level per-chromosome FASTA and AGP:

```bash
while read chr; do
    perl split_scaffold_by_agp.pl \
        raw_agp \
        raw_genome \
        "${chr}" \
        round1/ref/${chr}.ctg.agp \
        round1/ref/${chr}.ptg.fa
done < chr.list
```

This produces, for each `chr`:

- `round1/ref/${chr}.ctg.agp` — contig-level AGP for that chromosome
- `round1/ref/${chr}.ptg.fa`   — contig-level FASTA for that chromosome  
  (these are the **target** sequences for patching)

You also need a **global** contig-level FASTA that concatenates all `*.ptg.fa` for the minimap2 alignment in the next step. The original workflow uses a pre-built `ptg_round1` file; if you do not have one, you can concatenate:

```bash
cat round1/ref/*.ptg.fa > ptg_round1.fa
```

---

## 3. Map patching contigs to the contig-level target assembly

Align the patching contigs (`ctg.fa`) to the contig-level assembly (`ptg_round1.fa`) using minimap2 (assembly-to-assembly mode):

```bash
minimap2 -x asm5 -t 32 ptg_round1.fa ctg.fa > round1/maps/ctg_vs_ptg.raw.paf
```

You can adjust `-t` according to your available CPUs.

---

## 4. Filter alignments by alignment-level error (de-tag)

Filter out low-quality alignments based on the `de:f:` tag (relative error rate) in the PAF file using `filter_paf_by_de.pl`:

```bash
perl filter_paf_by_de.pl round1/maps/ctg_vs_ptg.raw.paf > round1/maps/ctg_vs_ptg.filtered.paf
```

The thresholds used for `de` and `ms` are hard-coded in the script and correspond to the ones used in the original pipeline (e.g. `de_utg_threshold`, `de_ont_threshold`).

You can optionally replace the original file:

```bash
mv round1/maps/ctg_vs_ptg.filtered.paf round1/maps/ctg_vs_ptg.paf
```

---

## 5. Enrich candidate contigs near gaps

Use `gap_patch_candidate_enrichment.pl` to identify contig ends that are good candidates for patching gaps. This script:

- inspects the positions of contig alignments from the filtered PAF,
- uses `raw_agp` to locate gaps,
- applies thresholds on `de`, `ms`, and distance to gap boundaries,
- outputs candidate contig–gap pairs.

Run:

```bash
perl gap_patch_candidate_enrichment.pl \
    ptg_round1.fa \
    ctg.fa \
    raw_agp \
    round1/maps/ctg_vs_ptg.paf \
    round1/candidates/ctg_all.Flanking_region.bed \
    round1/candidates/ctg.Flanking_region.list \
    --de-thr 0.001 \
    --ms-thr 15000 \
    --max-gap-margin 5000000
```

- `ctg_all.Flanking_region.bed` — flanking intervals of candidate contig ends
- `ctg.Flanking_region.list` — tab-delimited summary of candidate contig–gap pairs (used below)

You can tune `--de-thr`, `--ms-thr`, and `--max-gap-margin` if needed.

---

## 6. Build per-chromosome candidate contig sets

For each chromosome, extract the list of contig IDs that are candidates for patching gaps on that chromosome, then build a per-chromosome FASTA of candidate contigs.

### 6.1 Extract contig IDs per chromosome

Assuming `ctg.Flanking_region.list` has contig IDs in **column 4**, create an ID list per chromosome:

```bash
while read chr; do
    awk -v c="${chr}" '$1 == c {print $4}' round1/candidates/ctg.Flanking_region.list \
        | sort -u > round1/candidates/${chr}.ctg.ids
done < chr.list
```

Adjust the column index if your `ctg.Flanking_region.list` format is slightly different.

### 6.2 Extract candidate contig sequences

Use `seqkit` (or `samtools faidx`) to extract the candidate contigs for each chromosome:

```bash
while read chr; do
    seqkit faidx ctg.fa \
        -f round1/candidates/${chr}.ctg.ids \
        > round1/ctg/${chr}.ctg.fa
done < chr.list
```

Now, for each `chr`, you have:

- `round1/ref/${chr}.ptg.fa` — target contig-level assembly for that chromosome
- `round1/ctg/${chr}.ctg.fa` — candidate patching contigs for that chromosome

---

## 7. Patch each chromosome with RagTag

For each chromosome, run `ragtag.py patch` to perform homology-based gap patching:

```bash
while read chr; do
    outdir="round1/ragtag/${chr}"
    mkdir -p "${outdir}"

    ragtag.py patch \
        -t 32 \
        --aligner minimap2 \
        --mm2-params "-x asm5" \
        -o "${outdir}" \
        round1/ref/${chr}.ptg.fa \
        round1/ctg/${chr}.ctg.fa
done < chr.list
```

This will create, for each `chr`:

- `${outdir}/ragtag.patch.agp`
- `${outdir}/ragtag.patch.fasta`
- `${outdir}/ragtag.patch.err` (log file)

You can adjust thread count (`-t`) and minimap2 parameters as needed.

---

## 8. Collapse per-chromosome AGPs back to genome-level AGP/FASTA

Finally, convert the per-chromosome patched AGPs into a genome-level AGP/FASTA that matches the original scaffold IDs using `collapse_chr_from_agp.pl`.

First, prepare a list of patched AGP files. For example:

```bash
ls round1/ragtag/*/ragtag.patch.agp > round1/patched_agp.list
```

Then run (example syntax; adapt to your script’s exact usage):

```bash
perl collapse_chr_from_agp.pl \
    raw_agp \
    chr.list \
    round1/patched_agp.list \
    round1/LG-Patch.round1.agp \
    round1/LG-Patch.round1.fa
```

### Notes

- `collapse_chr_from_agp.pl` restores the original scaffold names and ordering based on `raw_agp` and `chr.list`, replacing each chromosome segment with its patched version from `ragtag.patch.agp`.
- If your script expects patched AGPs as individual arguments rather than via a list file, you can expand them using command substitution, for example:
  ```bash
  perl collapse_chr_from_agp.pl raw_agp chr.list \
      $(ls round1/ragtag/*/ragtag.patch.agp) \
      round1/LG-Patch.round1.agp \
      round1/LG-Patch.round1.fa
  ```

---

## 9. Running additional rounds

To perform a second (or later) round of gap patching:

1. Use `LG-Patch.round1.fa` and `LG-Patch.round1.agp` as the new `raw_genome` / `raw_agp`.
2. Generate an updated `chr.list` if scaffold IDs changed.
3. Choose a new contig set (e.g. ONT-only contigs).
4. Repeat **Steps 2–8** with a new working directory (e.g. `round2/`).

You can iterate until additional patching no longer improves the assembly or all large gaps of interest are resolved.

## Contacts
Pengzheng Lei()
