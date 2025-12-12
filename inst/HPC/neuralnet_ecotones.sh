#!/bin/bash -e

#SBATCH --job-name=systematic_test_neuralnet_selforg
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 4
#SBATCH --ntasks=1
#SBATCH --mem=10G
#SBATCH --time=10:00:00
#SBATCH --qos=standard
#SBATCH --output=nn_ecotones_%j.out

module add GDAL
module add R

Rscript systematic_test_neuralnet.R ecotones ../analyses/data/

