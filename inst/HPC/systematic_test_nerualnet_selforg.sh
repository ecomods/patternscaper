#!/bin/bash -e

#SBATCH --job-name=systematic_test_neuralnet_selforg
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=2048
#SBATCH --time=00:05:00
#SBATCH --qos=standard

module add R

Rscript "systematic_test_neuralnet_selforg.R" 