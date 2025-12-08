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
#SBATCH --output=keras_test_%j.out
#SBATCH --error=keras_test_%j.err

module add R

# Test 1: Try with scratch directory

export SCRATCH_DIR="/scratch/$USER/keras_test_$SLURM_JOB_ID"
mkdir -p "$SCRATCH_DIR"

export RETICULATE_MINICONDA_PATH="$SCRATCH_DIR/miniconda"
export UV_CACHE_DIR="$SCRATCH_DIR/uv_cache"
export KERAS_HOME="$SCRATCH_DIR/keras"
export TMPDIR="$SCRATCH_DIR/tmp"

echo "SCRATCH_DIR: $SCRATCH_DIR"
echo "RETICULATE_MINICONDA_PATH: $RETICULATE_MINICONDA_PATH"

Rscript test_keras_minimal.R

echo "Contents of scratch dir:"
ls -la "$SCRATCH_DIR" || echo "Directory is empty or doesn't exist"

# Cleanup
rm -rf "$SCRATCH_DIR"