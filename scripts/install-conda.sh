#!/usr/bin/env bash
set -xe

curl -sL -o miniconda.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
sh ./miniconda.sh -b -p /opt/conda
rm miniconda.sh

mkdir -p /etc/conda
cat <<EOF > /etc/conda/condarc
always_yes: true
changeps1: false
auto_update_conda: false
aggressive_update_packages: []
envs_dirs:
 - /home/conda/environments
EOF

# Fix permissions in accordance with jupyter stack permissions
# model
fix-permissions /opt/conda /etc/conda /etc/profile.d
