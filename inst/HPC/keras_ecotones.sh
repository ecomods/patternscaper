#!/bin/bash -e

#SBATCH --job-name=keras_ecotones
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=5G
#SBATCH --time=00:05:00
#SBATCH --qos=standard
#SBATCH --array=1-2
#SBATCH --output=keras_ecotones_test_re_%a_%j.out

module add GDAL
module add R

# Run the R script with arguments
Rscript "systematic_test_keras.R" ecotones results/keras/ecotones ${SLURM_ARRAY_TASK_ID}
