# =============================================================================
# Nebari Docker Images - Hardened Multi-Stage Build
# =============================================================================
# Security priorities: non-root user, pinned bases, verified binaries, minimal runtime
# Reproducibility: manifest digests, version pins, audit labels
# Functionality: external env mounting, all current packages preserved

ARG UBUNTU_DIGEST=sha256:66460d557b25769b102175144d538d88219c077c678a49af4afca6fbfc1b5252
ARG DEFAULT_ENV=default

# Pixi version and checksums
ARG PIXI_VERSION=0.58.0
ARG PIXI_AMD64_SHA256=1e0b522fb770f170fab78ecabee7d0480e8025bfd951359c442bf47ef7ace09f
ARG PIXI_ARM64_SHA256=cd2a5d15312936bff4a8ae1856077480034a017c9067670e764745f370323c78

# =============================================================================
# Stage 1: Secure Pixi Installer
# =============================================================================
FROM ubuntu:24.04@${UBUNTU_DIGEST} AS pixi-installer
ARG PIXI_VERSION
ARG PIXI_AMD64_SHA256
ARG PIXI_ARM64_SHA256

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  wget \
  bzip2 \
  ca-certificates && \
  ARCH=$(dpkg --print-architecture) && \
  if [ "$ARCH" = "amd64" ]; then \
  PIXI_SHA256=${PIXI_AMD64_SHA256}; \
  PIXI_ARCH="x86_64"; \
  else \
  PIXI_SHA256=${PIXI_ARM64_SHA256}; \
  PIXI_ARCH="aarch64"; \
  fi && \
  wget -O /tmp/pixi "https://github.com/prefix-dev/pixi/releases/download/v${PIXI_VERSION}/pixi-${PIXI_ARCH}-unknown-linux-musl" && \
  echo "${PIXI_SHA256}  /tmp/pixi" | sha256sum -c - && \
  install -m 755 /tmp/pixi /usr/local/bin/pixi && \
  rm /tmp/pixi && \
  apt-get remove -y wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 2: Builder Base with Non-Root User
# =============================================================================
FROM ubuntu:24.04@${UBUNTU_DIGEST} AS builder

COPY --from=pixi-installer /usr/local/bin/pixi /usr/local/bin/pixi
COPY scripts /opt/scripts

RUN userdel -r ubuntu 2>/dev/null || true && \
  useradd -m -u 1000 -g 100 -s /bin/bash nebari && \
  mkdir -p /opt/envs && \
  chown -R nebari:users /home/nebari /opt/envs

ENV PATH=/usr/local/bin:/opt/scripts:${PATH}
ENV DEFAULT_ENV=default

# Install minimal build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  git && \
  rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 3: Dask-Worker Builder
# =============================================================================
FROM builder AS dask-worker-builder
ARG DEFAULT_ENV

# Note: git-lfs moved to pixi (no additional apt packages needed for builder)

# Switch to nebari for environment creation
USER nebari
WORKDIR /home/nebari

# Install pixi environment
COPY --chown=nebari:users dask-worker/pixi.toml dask-worker/pixi.lock /opt/dask-worker/
RUN pixi install --manifest-path /opt/dask-worker/pixi.toml -e ${DEFAULT_ENV} --locked && \
  pixi clean cache --yes

# Run postBuild as root (creates files in /opt)
USER root
COPY dask-worker/postBuild /opt/dask-worker/
RUN chmod +x /opt/dask-worker/postBuild && /opt/dask-worker/postBuild
USER nebari

# =============================================================================
# Stage 4: Dask-Worker Runtime
# =============================================================================
FROM ubuntu:24.04@${UBUNTU_DIGEST} AS dask-worker
ARG UBUNTU_DIGEST
ARG PIXI_VERSION
ARG DEFAULT_ENV

# Copy user/group configuration
COPY --from=builder /etc/passwd /etc/group /etc/shadow /etc/

# Copy pixi binary and scripts
COPY --from=pixi-installer /usr/local/bin/pixi /usr/local/bin/pixi
COPY --from=builder /opt/scripts/fix-permissions /usr/local/bin/

# Install only runtime libraries
# Note: git-lfs moved to pixi
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# Copy installed environment
COPY --from=dask-worker-builder --chown=nebari:users /opt/dask-worker /opt/dask-worker
COPY --from=dask-worker-builder --chown=nebari:users /opt/conda-run-worker /opt/conda-run-worker
COPY --from=dask-worker-builder --chown=nebari:users /opt/conda-run-scheduler /opt/conda-run-scheduler

# Create mount point for external envs
RUN mkdir -p /opt/envs && chown nebari:users /opt/envs && chmod 775 /opt/envs

# Environment setup
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64
ENV NVIDIA_PATH=/usr/local/nvidia/bin
ENV PATH=/opt/envs/${DEFAULT_ENV}/bin:/opt/dask-worker/.pixi/envs/${DEFAULT_ENV}/bin:${NVIDIA_PATH}:/usr/local/bin:${PATH}
ENV HOME=/home/nebari

USER nebari
WORKDIR /home/nebari

LABEL org.opencontainers.image.base.name="ubuntu" \
  org.opencontainers.image.base.digest="${UBUNTU_DIGEST}" \
  dev.nebari.pixi.version="${PIXI_VERSION}" \
  dev.nebari.component="dask-worker" \
  MAINTAINER="Nebari development team"

# =============================================================================
# Stage 5: JupyterHub Builder
# =============================================================================
FROM builder AS jupyterhub-builder

USER nebari
WORKDIR /home/nebari

# Install pixi environment
COPY --chown=nebari:users jupyterhub/pixi.toml jupyterhub/pixi.lock /opt/jupyterhub/
RUN pixi install --manifest-path /opt/jupyterhub/pixi.toml -e ${DEFAULT_ENV} --locked && \
  pixi clean cache --yes

# Run postBuild (if it needs root access, run as root)
USER root
COPY jupyterhub/postBuild /opt/jupyterhub/
RUN chmod +x /opt/jupyterhub/postBuild && \
  chown nebari:users /opt/jupyterhub/postBuild
USER nebari
RUN /opt/jupyterhub/postBuild || true

# =============================================================================
# Stage 6: JupyterHub Runtime
# =============================================================================
FROM ubuntu:24.04@${UBUNTU_DIGEST} AS jupyterhub
ARG DEFAULT_ENV
ARG UBUNTU_DIGEST
ARG PIXI_VERSION

# Copy user/group configuration
COPY --from=builder /etc/passwd /etc/group /etc/shadow /etc/

# Copy pixi binary and scripts
COPY --from=pixi-installer /usr/local/bin/pixi /usr/local/bin/pixi
COPY --from=builder /opt/scripts/fix-permissions /usr/local/bin/

# Install only runtime libraries
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# Copy installed environment
COPY --from=jupyterhub-builder --chown=nebari:users /opt/jupyterhub /opt/jupyterhub

# Create mount point and working directory
RUN mkdir -p /opt/envs /srv/jupyterhub && \
  chown nebari:users /opt/envs /srv/jupyterhub && \
  chmod 775 /opt/envs /srv/jupyterhub

WORKDIR /srv/jupyterhub

# Environment setup
ENV PATH=/opt/envs/${DEFAULT_ENV}/bin:/opt/jupyterhub/.pixi/envs/${DEFAULT_ENV}/bin:/usr/local/bin:${PATH}
ENV HOME=/home/nebari

USER nebari

LABEL org.opencontainers.image.base.name="ubuntu" \
  org.opencontainers.image.base.digest="${UBUNTU_DIGEST}" \
  dev.nebari.pixi.version="${PIXI_VERSION}" \
  dev.nebari.component="jupyterhub" \
  MAINTAINER="Nebari development team"

CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]

# =============================================================================
# Stage 7: JupyterLab Base (Intermediate)
# =============================================================================
FROM builder AS intermediate

RUN chmod -R a-w /root

ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  TZ=UTC

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install common packages for jupyterlab and workflow-controller
# Note: htop, tree, zip, unzip, openssh, tmux, nano, vim moved to pixi
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  locales \
  libnss-wrapper \
  xvfb \
  emacs && \
  rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 8: JupyterLab Builder
# =============================================================================
FROM intermediate AS jupyterlab-builder

# Install jupyterlab-specific packages
# Note: zsh, neovim, git-lfs, wget, curl moved to pixi
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  libgl1 \
  libglx-mesa0 \
  libxrandr2 \
  libxss1 \
  libxcursor1 \
  libxcomposite1 \
  libasound2t64 \
  libxi6 \
  libxtst6 \
  libfontconfig1 \
  libxrender1 \
  libosmesa6 \
  gnupg \
  pinentry-curses && \
  rm -rf /var/lib/apt/lists/*

# Switch to nebari for environment creation
USER nebari
WORKDIR /home/nebari

# Install pixi environment
COPY --chown=nebari:users jupyterlab/pixi.toml jupyterlab/pixi.lock /opt/jupyterlab/
RUN pixi install --manifest-path /opt/jupyterlab/pixi.toml -e ${DEFAULT_ENV} --locked && \
  pixi clean cache --yes

# Run postBuild as root (code-server installation creates /opt/tmpdir)
USER root
COPY jupyterlab/postBuild /opt/jupyterlab/
RUN chmod +x /opt/jupyterlab/postBuild && \
  pixi run --manifest-path /opt/jupyterlab/pixi.toml -e ${DEFAULT_ENV} /opt/jupyterlab/postBuild

# =============================================================================
# Stage 9: JupyterLab Runtime
# =============================================================================
FROM ubuntu:24.04@${UBUNTU_DIGEST} AS jupyterlab
ARG DEFAULT_ENV
ARG UBUNTU_DIGEST
ARG PIXI_VERSION

# Copy user/group configuration
COPY --from=builder /etc/passwd /etc/group /etc/shadow /etc/

# Copy pixi binary and scripts
COPY --from=pixi-installer /usr/local/bin/pixi /usr/local/bin/pixi
COPY --from=builder /opt/scripts/fix-permissions /usr/local/bin/

# Install runtime libraries (all the UI/graphics libraries jupyterlab needs)
# Note: openssh-client, tmux, git-lfs moved to pixi
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  locales \
  libnss-wrapper \
  libgl1 \
  libglx-mesa0 \
  libxrandr2 \
  libxss1 \
  libxcursor1 \
  libxcomposite1 \
  libasound2t64 \
  libxi6 \
  libxtst6 \
  libfontconfig1 \
  libxrender1 \
  libosmesa6 \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# Copy installed environment
COPY --from=jupyterlab-builder --chown=nebari:users /opt/jupyterlab /opt/jupyterlab

# Create mount point
RUN mkdir -p /opt/envs && chown nebari:users /opt/envs && chmod 775 /opt/envs

# Environment setup
ENV PATH=/opt/envs/${DEFAULT_ENV}/bin:/opt/jupyterlab/.pixi/envs/${DEFAULT_ENV}/bin:/opt/jupyterlab/.pixi/envs/${DEFAULT_ENV}/share/code-server/bin:/usr/local/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64
ENV NVIDIA_PATH=/usr/local/nvidia/bin
ENV PATH=${NVIDIA_PATH}:${PATH}
ENV HOME=/home/nebari
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

USER nebari
WORKDIR /home/nebari

LABEL org.opencontainers.image.base.name="ubuntu" \
  org.opencontainers.image.base.digest="${UBUNTU_DIGEST}" \
  dev.nebari.pixi.version="${PIXI_VERSION}" \
  dev.nebari.component="jupyterlab" \
  MAINTAINER="Nebari development team"

# =============================================================================
# Stage 10: Workflow Controller Builder
# =============================================================================
FROM intermediate AS workflow-controller-builder

USER nebari
WORKDIR /home/nebari

# Install pixi environment
COPY --chown=nebari:users nebari-workflow-controller/pixi.toml nebari-workflow-controller/pixi.lock /opt/nebari-workflow-controller/
RUN pixi install --manifest-path "/opt/nebari-workflow-controller/pixi.toml" -e "${DEFAULT_ENV}" --locked && \
  pixi clean cache --yes

# =============================================================================
# Stage 11: Workflow Controller Runtime
# =============================================================================
FROM ubuntu:24.04@${UBUNTU_DIGEST} AS workflow-controller
ARG DEFAULT_ENV
ARG UBUNTU_DIGEST
ARG PIXI_VERSION

# Copy user/group configuration
COPY --from=builder /etc/passwd /etc/group /etc/shadow /etc/

# Copy pixi binary
COPY --from=pixi-installer /usr/local/bin/pixi /usr/local/bin/pixi

# Install only runtime libraries
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# Copy installed environment
COPY --from=workflow-controller-builder --chown=nebari:users /opt/nebari-workflow-controller /opt/nebari-workflow-controller

# Create mount point
RUN mkdir -p /opt/envs && chown nebari:users /opt/envs && chmod 775 /opt/envs

# Environment setup
ENV PATH=/opt/envs/${DEFAULT_ENV}/bin:/opt/nebari-workflow-controller/.pixi/envs/${DEFAULT_ENV}/bin:/usr/local/bin:${PATH}
ENV HOME=/home/nebari

USER nebari
WORKDIR /home/nebari

LABEL org.opencontainers.image.base.name="ubuntu" \
  org.opencontainers.image.base.digest="${UBUNTU_DIGEST}" \
  dev.nebari.pixi.version="${PIXI_VERSION}" \
  dev.nebari.component="workflow-controller" \
  MAINTAINER="Nebari development team"

CMD ["python", "-m", "nebari_workflow_controller"]
