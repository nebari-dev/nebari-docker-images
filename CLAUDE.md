# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git Commit Guidelines

When creating commits or pull requests:
- **NEVER** add "Co-authored-by: Claude" or similar attribution to commit messages
- **NEVER** add co-authorship credits in commits or PRs

## Overview

This repository contains Docker image definitions for the [Nebari platform](https://nebari.dev). Images are built using a multi-stage Dockerfile and published to both GitHub Container Registry (ghcr.io) and Quay Container Registry (quay.io). The repo produces four main images: `nebari-jupyterlab`, `nebari-jupyterhub`, `nebari-dask-worker`, and `nebari-workflow-controller`, each with CPU and GPU variants (except jupyterhub and workflow-controller which are CPU-only).

## Build Commands

### Building Images Locally

Use the Makefile targets to build specific images:

```bash
# Build individual images
make jupyterlab          # Build nebari-jupyterlab
make jupyterhub          # Build nebari-jupyterhub
make dask-worker         # Build nebari-dask-worker
make workflow-controller # Build nebari-workflow-controller

# Build all images
make all

# Clean up built images
make clean
```

All builds use the single multi-stage `Dockerfile` with different `--target` flags.

### Pre-commit Hooks

```bash
# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files
```

The repository uses `prettier` for YAML/Markdown formatting and standard pre-commit hooks for trailing whitespace, end-of-file-fixer, etc.

## Architecture

### Multi-stage Docker Build

The `Dockerfile` uses a multi-stage build pattern with the following stages:

1. **`builder`** (base): Ubuntu 20.04 with Mambaforge conda installation
2. **`intermediate`**: Extends builder with common utilities (vim, tmux, zsh, etc.)
3. **`jupyterlab`**: Extends intermediate with JupyterLab, extensions, code-server
4. **`jupyterhub`**: Extends builder with JupyterHub
5. **`dask-worker`**: Extends builder with Dask dependencies
6. **`workflow-controller`**: Extends intermediate with nebari-workflow-controller

### Component Structure

Each image has a corresponding directory containing:
- `environment.yaml`: Conda/pip dependencies for the component
- `postBuild`: Shell script run after environment installation (executable)

Key component directories:
- `jupyterlab/`: JupyterLab with extensions (dask_labextension, jupyterlab-git, jupyter-ai, etc.)
- `jupyterhub/`: JupyterHub server configuration
- `dask-worker/`: Dask worker with `nebari-dask` metapackage
- `nebari-workflow-controller/`: Workflow controller service
- `scripts/`: Shared installation scripts used across all builds

### Installation Scripts

Located in `scripts/`, these are used during Docker builds:
- `install-conda.sh`: Installs Mambaforge (version 4.13.0-1)
- `install-conda-environment.sh`: Creates/updates conda environments from YAML or lock files
  - Supports `SKIP_CONDA_SOLVE` arg to use lock files instead of solving dependencies
  - Cleans conda cache and removes unnecessary files (`.a`, `.js.map`)
- `install-code-server.sh`: Installs VS Code server for JupyterLab
- `install-gitlfs.sh`: Installs git-lfs
- `fix-permissions`: Sets proper permissions for multi-user environments

### Critical Dependency Pinning

**IMPORTANT**: The `dask-gateway` and `distributed` packages must be pinned to matching versions between dask-worker images and the JupyterLab environment. Version mismatches will cause dask-workers to fail.

### GPU Support

GPU images are built with:
- Base image: `nvidia/cuda:12.2.2-base-ubuntu20.04` (vs `ubuntu:20.04` for CPU)
- `LD_LIBRARY_PATH=/usr/local/nvidia/lib64`
- `NVIDIA_PATH=/usr/local/nvidia/bin` added to `PATH`

GPU variants are built for `jupyterlab` and `dask-worker` only.

## CI/CD

### GitHub Actions Workflows

- **`build-push-docker.yaml`**: Builds and pushes images on changes to:
  - `Dockerfile`, component dirs (`jupyterlab/`, `jupyterhub/`, etc.), `scripts/`, or the workflow file itself
  - Builds matrix of images × platforms (cpu/gpu)
  - Pushes to both ghcr.io and quay.io with tags: branch name, branch-sha-date, and git tags
  - Uses Docker buildx with cache from GitHub Actions cache
  - Builds for `linux/amd64` and `linux/arm64` platforms

- **`test-images.yaml`**: Tests built images

### Image Naming Convention

Images follow the pattern:
- `nebari-{component}` for CPU variants
- `nebari-{component}-gpu` for GPU variants

Published to:
- `ghcr.io/nebari-dev/nebari-{component}[-gpu]`
- `quay.io/nebari/nebari-{component}[-gpu]`

## Development Notes

### Dockerfile Optimization

The Dockerfile uses BuildKit mount caches to speed up builds:
- `--mount=type=cache,target=/var/cache/apt,sharing=locked`: APT cache
- `--mount=type=cache,target=/var/lib/apt,sharing=locked`: APT lib
- `--mount=type=cache,target=/opt/conda/pkgs,sharing=locked`: Conda package cache
- `--mount=type=cache,target=/root/.cache/pip,sharing=locked`: Pip cache

### Conda Lock Files

The build supports using conda lock files (via `SKIP_CONDA_SOLVE` build arg) for reproducible builds. When set to `"no"` (default), it uses `environment.yaml`. When set to other values, it expects a lock file at `{component}/conda-linux-64.lock`.

### JupyterLab Extensions

The jupyterlab image includes extensive extensions installed via conda/pip:
- Dask integration: `dask_labextension`
- Git: `jupyterlab-git`
- AI: `jupyter-ai`
- Nebari-specific: `jupyterlab-nebari-mode`, `jupyterlab-conda-store`, `argo-jupyter-scheduler`, `jhub-apps`

Refer to `jupyterlab/environment.yaml` for the complete list and version pins.
