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
module add TensorFlow/2.2.0-fosscuda-2019b-Python-3.7.4

# Check loaded modules
echo "Loaded modules:"
module list
echo ""

# Check Python from TensorFlow module
echo "Python path: $(which python3 || which python || echo 'not found')"
echo "Python version: $(python3 --version 2>&1 || python --version 2>&1)"
echo ""

# Point reticulate to the TensorFlow module's Python
export RETICULATE_PYTHON=$(which python3 || which python)

# Set scratch directory for any additional cache
export SCRATCH_DIR="/scratch/$USER/keras_test_$SLURM_JOB_ID"
mkdir -p "$SCRATCH_DIR"

export UV_CACHE_DIR="$SCRATCH_DIR/uv_cache"
export KERAS_HOME="$SCRATCH_DIR/keras"
export TMPDIR="$SCRATCH_DIR/tmp"

echo "Environment variables:"
echo "  RETICULATE_PYTHON: $RETICULATE_PYTHON"
echo "  SCRATCH_DIR: $SCRATCH_DIR"
echo ""

Rscript test_keras_minimal.R

echo ""
echo "Contents of scratch dir:"
ls -laR "$SCRATCH_DIR" 2>/dev/null || echo "Directory is empty"

# Cleanup
rm -rf "$SCRATCH_DIR"