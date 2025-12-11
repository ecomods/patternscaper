#!/bin/bash -e

#SBATCH --job-name=systematic_test_neuralnet_selforg
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 4
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --time=24:00:00
#SBATCH --qos=standard

module add GDAL
module add R

Rscript "systematic_test_neuralnet_ecotone.R" 
