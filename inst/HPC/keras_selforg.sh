#!/bin/bash -e

#SBATCH --job-name=keras_selforg
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=7G
#SBATCH --time=19:00:00
#SBATCH --qos=standard
#SBATCH --array=1,2,3,5,6,10
#SBATCH --output=log/keras_selforg_rep_%a_%j.out

module add GDAL
module add R

# Run the R script with arguments
Rscript "systematic_test_keras.R" selforg results/keras/selforg ${SLURM_ARRAY_TASK_ID}