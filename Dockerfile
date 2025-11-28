ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE} AS builder
LABEL MAINTAINER="Nebari development team"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    curl \
    git 

COPY scripts /opt/scripts

RUN curl -fsSL https://pixi.sh/install.sh | bash

ENV PATH=/root/.pixi/bin:/opt/scripts:${PATH}

ENV DEFAULT_ENV=default


# ========== dask-worker install ===========
FROM builder AS dask-worker

ARG GPU
ENV LD_LIBRARY_PATH=${GPU:+/usr/local/nvidia/lib64}
ENV NVIDIA_PATH=${GPU:+/usr/local/nvidia/bin}
ENV PATH=${GPU:+/usr/local/nvidia/bin:}${PATH}

COPY --from=builder /root/.pixi /root/.pixi
COPY dask-worker/pixi.toml /opt/dask-worker/pixi.toml
COPY dask-worker/pixi.lock /opt/dask-worker/pixi.lock
RUN --mount=type=cache,target=/root/.cache/rattler/cache,sharing=locked \
    pixi install --manifest-path /opt/dask-worker/ -e ${DEFAULT_ENV} --locked

COPY dask-worker /opt/dask-worker
RUN /opt/dask-worker/postBuild

ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64
ENV NVIDIA_PATH=/usr/local/nvidia/bin
ENV PATH=/opt/dask-worker/.pixi/envs/${DEFAULT_ENV}/bin:${NVIDIA_PATH}:$PATH


# ========== jupyterhub install ===========
FROM builder AS jupyterhub

COPY --from=builder /root/.pixi /root/.pixi
COPY jupyterhub/pixi.toml /opt/jupyterhub/pixi.toml
COPY jupyterhub/pixi.lock /opt/jupyterhub/pixi.lock
RUN --mount=type=cache,target=/root/.cache/rattler/cache,sharing=locked \
    pixi install --manifest-path /opt/jupyterhub/ -e ${DEFAULT_ENV} --locked

COPY jupyterhub /opt/jupyterhub
RUN /opt/jupyterhub/postBuild

WORKDIR /srv/jupyterhub

# So we can actually write a db file here
RUN fix-permissions /srv/jupyterhub

ENV PATH=/opt/jupyterhub/.pixi/envs/${DEFAULT_ENV}/bin:${PATH}

CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]


# ========== jupyterlab base ===========
FROM builder AS intermediate
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN chmod -R a-w ~
ENV TZ=UTC
# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    locales \
    libnss-wrapper \
    htop \
    tree \
    zip \
    unzip \
    openssh-client \
    tmux \
    xvfb \
    nano \
    vim \
    emacs


# ========== jupyterlab install ===========
FROM intermediate AS jupyterlab

ARG GPU

ENV CONDA_DIR=/opt/conda \
    DEFAULT_ENV=default \
    LD_LIBRARY_PATH=${GPU:+/usr/local/nvidia/lib64} \
    NVIDIA_PATH=${GPU:+/usr/local/nvidia/bin}

ENV PATH=${GPU:+/usr/local/nvidia/bin:}${PATH}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    neovim \
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
    pinentry-curses \
    git-lfs

COPY --from=builder /root/.pixi /root/.pixi
COPY jupyterlab/pixi.toml /opt/jupyterlab/pixi.toml
COPY jupyterlab/pixi.lock /opt/jupyterlab/pixi.lock
RUN --mount=type=cache,target=/root/.cache/rattler/cache,sharing=locked \
    pixi install --manifest-path /opt/jupyterlab/ -e ${DEFAULT_ENV} --locked

# ========== code-server install ============
ENV PATH=/opt/jupyterlab/.pixi/envs/${DEFAULT_ENV}/share/code-server/bin:${PATH}

COPY jupyterlab /opt/jupyterlab
RUN /opt/jupyterlab/postBuild

ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64
ENV NVIDIA_PATH=/usr/local/nvidia/bin
ENV PATH=/opt/jupyterhub/.pixi/envs/${DEFAULT_ENV}/bin:${NVIDIA_PATH}:$PATH


# ========== nebari-workflow-controller install ============
FROM intermediate AS workflow-controller

COPY --from=builder /root/.pixi /root/.pixi
COPY nebari-workflow-controller/pixi.toml /opt/nebari-workflow-controller/pixi.toml
COPY nebari-workflow-controller/pixi.lock /opt/nebari-workflow-controller/pixi.lock
RUN --mount=type=cache,target=/root/.cache/rattler/cache,sharing=locked \
    pixi install --manifest-path /opt/nebari-workflow-controller/ -e ${DEFAULT_ENV} --locked

ENV PATH=/opt/nebari-workflow-controller/.pixi/envs/${DEFAULT_ENV}/bin:${PATH}

CMD ["python", "-m", "nebari_workflow_controller"]
