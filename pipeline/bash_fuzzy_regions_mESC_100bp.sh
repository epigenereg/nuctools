#!/bin/bash
#
#$ -cwd
#$ -q all.q
#$ -S /bin/bash
#$ -m e 

cd /storage/projects/mESC/100bp_ESC/fuzzy_nucs_ESC

perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr1 --output=chr1_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr1"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr2 --output=chr2_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr2"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr3 --output=chr3_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr3"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr4 --output=chr4_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr4"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr5 --output=chr5_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr5"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr6 --output=chr6_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr6"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr7 --output=chr7_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr7"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr8 --output=chr8_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr8"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr9 --output=chr9_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr9"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr10 --output=chr10_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr10"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr11 --output=chr11_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr11"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr12 --output=chr12_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr12"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr13 --output=chr13_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr13"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr14 --output=chr14_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr14"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr15 --output=chr15_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr15"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr16 --output=chr16_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr16"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr17 --output=chr17_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr17"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr18 --output=chr18_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr18"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chr19 --output=chr19_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chr19"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chrX --output=chrX_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chrX"
perl /storage/projects/nuctools.2.0/stable_nucs_replicates.pl --inputDir=/storage/projects/mESC/100bp_ESC/chrY --output=chrY_stable_mESC_100bp.txt --fileExtention=occ --coordsCol=0 --occupCol=1 --fuzzy --StableThreshold=2 --chromosome="chrY"