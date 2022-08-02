#!/usr/bin/env bash
set -xe
# Requires environment MAMBAFORGE_SHA256, MINIFORGE_VERSION, and DEFAULT_ENV
wget --quiet -O mambaforge.sh https://github.com/conda-forge/miniforge/releases/download/$MAMBAFORGE_VERSION/Mambaforge-Linux-x86_64.sh
echo "${MAMBAFORGE_SHA256} mambaforge.sh" > mambaforge.checksum

echo $(sha256sum -c mambaforge.checksum)

if [ $(sha256sum -c mambaforge.checksum | awk '{print $2}') != "OK" ]; then
   echo Error when testing checksum
   exit 1;
fi

sh ./mambaforge.sh -b -p /opt/conda
rm mambaforge.sh mambaforge.checksum

# Check Mamba install and clean up
mamba --version
mamba clean -afy

ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

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
