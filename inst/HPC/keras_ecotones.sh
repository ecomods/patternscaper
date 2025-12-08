#!/bin/bash -e

#SBATCH --job-name=keras_ecotones
#SBATCH --mail-user=ujcuz@zedat.fu-berlin.de
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --time=48:00:00
#SBATCH --qos=standard

module add R

# Configure environment for Keras
export SCRATCH_DIR="/scratch/$USER/keras_job_$SLURM_JOB_ID"
mkdir -p "$SCRATCH_DIR"

# Point all reticulate/keras cache to local scratch (not NFS home directory)
export RETICULATE_MINICONDA_PATH="$SCRATCH_DIR/miniconda"
export UV_CACHE_DIR="$SCRATCH_DIR/uv_cache"
export KERAS_HOME="$SCRATCH_DIR/keras"
export TMPDIR="$SCRATCH_DIR/tmp"

echo "Using cache directory: $SCRATCH_DIR"

# Run the R script with arguments
Rscript "systematic_test_keras.R" ecotones results_ecotones 