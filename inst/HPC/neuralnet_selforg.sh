#!/bin/bash -e

#SBATCH --job-name=systematic_neuralnet_selforg
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=7G
#SBATCH --time=07:30:00
#SBATCH --qos=standard
#SBATCH --array=1-10
#SBATCH --output=log/nn_selforg_rep_%a_%j.out

module add GDAL
module add R

# Run the R script with arguments
Rscript "systematic_test_neuralnet.R" selforg results/nn_metrics/selforg/ ${SLURM_ARRAY_TASK_ID}