#!/bin/bash -e

#SBATCH --job-name=keras_pkg_test
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --qos=standard

module add GDAL
module add R

Rscript "test_keras_pkg.R"