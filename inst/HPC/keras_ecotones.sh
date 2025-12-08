#!/bin/bash -e

#SBATCH --job-name=keras_ecotones
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --qos=standard

module add GDAL
module add R

# Run the R script with arguments
Rscript "systematic_test_keras.R" ecotones results_ecotones 
