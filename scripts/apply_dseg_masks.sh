#!/bin/bash
# =============================================================================
# Purpose: Apply QSIPrep MNI152NLin2009cAsym -> subject ACPC transform to multiple
#          MNI-space binary/label masks and resample them into each subject's
#          ACPC-space DWI reference grid (dwiref). The resulting subject-space
#          masks are prerequisites for region-wise brain coverage metrics
#          (e.g., cerebrum, cerebellum, brainstem).
#
# Created on 2026-01-29 by Samantha Keppler
#
# Requirements:
# - Docker
# - antsx/ants:2.5.3 container image (pulled automatically by docker run)
# - QSIPrep outputs containing:
#   - sub-<ID>/anat/sub-<ID>_from-MNI152NLin2009cAsym_to-ACPC_mode-image_xfm.h5
#   - sub-<ID>/dwi/sub-<ID>_dir-*_space-ACPC_dwiref.nii.gz
#
# Notes:
# - Uses NearestNeighbor interpolation for binary/label masks.
# - Skips work if inputs are missing or outputs already exist.
# =============================================================================
set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

CONFIG=(
  # Dataset paths
  ["bids_dir"]="/mnt/synapse/neurocat-lab/R21MH133229_asd_dmri_lifespan/datasets_v1.0/abideii-ip"
  ["qsiprep_version"]="qsiprep-1.0.0rc2"
  ["sj_list_file"]="/mnt/synapse/neurocat-lab/R21MH133229_asd_dmri_lifespan/datasets_v1.0/abideii-ip/code/sj_list.txt"

  # Mask inputs (MNI space)
  ["mni_masks_dir"]="/mnt/synapse/neurocat-lab/atlases/MNI152NLin2009cAsym_res-01_dseg_masks"

  # Transform name (QSIPrep composite transform: MNI152NLin2009cAsym -> ACPC)
  ["xfm_name_template"]="sub-{subj}_from-MNI152NLin2009cAsym_to-ACPC_mode-image_xfm.h5"

  # Docker image containing antsApplyTransforms
  ["ants_docker_image"]="antsx/ants:2.5.3"

  # Interpolation for label/binary masks
  ["interp"]="NearestNeighbor"
)

# Masks (filenames must exist under CONFIG[mni_masks_dir])
MASKS=(
  "cerebrum.nii.gz"
  "cerebellum+midbrain.nii.gz"
  "brainstem.nii.gz"
)

# Output tags (used in output filenames); key is mask stem without .nii.gz
declare -A OUTTAG=(
  ["cerebrum"]="mni_cerebrum_brain_coverage_mask"
  ["cerebellum_and_midbrain"]="mni_cerebellum_and_midbrain_brain_coverage_mask"
  ["brainstem"]="mni_brainstem_brain_coverage_mask"
)