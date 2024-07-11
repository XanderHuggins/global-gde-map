#!/bin/bash

#SBATCH --account=def-tgleeson
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xanderhuggins@uvic.ca
#SBATCH --time=0-01:00:00
#SBATCH --mem=50G
#SBATCH --array=1-436  
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --nodes=1
#SBATCH --job-name=GDE_tiles
#SBATCH --output=slurm_files/GDE_tile_%a.out 
#SBATCH --error=slurm_files/GDE_tile_%a.err 

module load StdEnv/2023  gcc/12.3  udunits/2.2.28  hdf/4.2.16  gdal/3.7.2  r/4.3.1

Rscript 01_GDE_tile_posthoc.R $SLURM_ARRAY_TASK_ID
