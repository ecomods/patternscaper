#!/bin/bash -e

#SBATCH --job-name=keras_test
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00
#SBATCH --qos=standard

module add R
#module add TensorFlow/2.2.0-fosscuda-2019b-Python-3.7.4

Rscript "test_keras.R"

