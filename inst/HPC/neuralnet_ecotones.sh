#!/bin/bash -e

#SBATCH --job-name=systematic_test_neuralnet_selforg
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --qos=standard
#SBATCH --array=1-2
#SBATCH --output=log/nn_ecotones_test_rep_%a_%j.out

module add GDAL
module add R

# Run the R script with arguments
Rscript "systematic_test_neuralnet.R" ecotones results/nn_metrics/ecotones/ ${SLURM_ARRAY_TASK_ID}

