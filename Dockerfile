ARG BASE_IMAGE=ubuntu:24.04
FROM $BASE_IMAGE as builder
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

ENV MAMBAFORGE_VERSION=4.13.0-1 \
    MAMBAFORGE_AARCH64_SHA256=69e3c90092f61916da7add745474e15317ed0dc6d48bfe4e4c90f359ba141d23 \
    MAMBAFORGE_X86_64_SHA256=412b79330e90e49cf7e39a7b6f4752970fcdb8eb54b1a45cc91afe6777e8518c \
    PATH=/opt/conda/bin:${PATH}:/opt/scripts


RUN /opt/scripts/install-conda.sh



# ========== dask-worker install ===========
FROM builder AS dask-worker
COPY dask-worker/environment.yaml /opt/dask-worker/environment.yaml
RUN --mount=type=cache,target=/root/.cache/conda \
    --mount=type=cache,target=/opt/conda/pkgs \/
    /opt/scripts/install-conda-environment.sh /opt/dask-worker/environment.yaml 'false'

ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64
ENV NVIDIA_PATH=/usr/local/nvidia/bin
ENV PATH="$NVIDIA_PATH:$PATH"

COPY dask-worker /opt/dask-worker
RUN /opt/dask-worker/postBuild





# ========== jupyterhub install ===========
FROM builder AS jupyterhub
COPY jupyterhub/environment.yaml /opt/jupyterhub/environment.yaml
RUN --mount=type=cache,target=/root/.cache/conda \
    --mount=type=cache,target=/opt/conda/pkgs \
    /opt/scripts/install-conda-environment.sh /opt/jupyterhub/environment.yaml 'false'

COPY jupyterhub /opt/jupyterhub
RUN /opt/jupyterhub/postBuild

WORKDIR /srv/jupyterhub

# So we can actually write a db file here
RUN fix-permissions /srv/jupyterhub

CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]




# ========== jupyterlab base ===========
FROM builder AS jupyterlab-base
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN chmod -R a-w ~
ENV TZ=UTC \
    PATH=/opt/conda/envs/${DEFAULT_ENV}/bin:/opt/conda/bin:${PATH}:/opt/scripts
# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone



# ========== jupyterlab install ===========
FROM jupyterlab-base AS jupyterlab

COPY jupyterlab/apt.txt /opt/jupyterlab/apt.txt
RUN /opt/scripts/install-apt.sh /opt/jupyterlab/apt.txt && \
    /opt/scripts/install-gitlfs.sh

ARG SKIP_CONDA_SOLVE=no
COPY jupyterlab/environment.yaml /opt/jupyterlab/environment.yaml
RUN --mount=type=cache,target=/root/.cache/conda \
    --mount=type=cache,target=/opt/conda/pkgs \
    if [ "${SKIP_CONDA_SOLVE}" != "no" ];then  \
    ENV_FILE=/opt/jupyterlab/conda-linux-64.lock ; \
    else  \
    ENV_FILE=/opt/jupyterlab/environment.yaml ; \
    fi ; \
    /opt/scripts/install-conda-environment.sh "${ENV_FILE}" 'true'

# ========== code-server install ============
ENV PATH=/opt/conda/envs/${DEFAULT_ENV}/share/code-server/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib64 \
    NVIDIA_PATH=/usr/local/nvidia/bin \
    PATH="$NVIDIA_PATH:$PATH"

COPY jupyterlab /opt/jupyterlab
RUN /opt/jupyterlab/postBuild





# ========== nebari-workflow-controller install ============
FROM jupyterlab-base AS workflow-controller

COPY nebari-workflow-controller/apt.txt /opt/nebari-workflow-controller/apt.txt
RUN /opt/scripts/install-apt.sh

# uncomment to install dev dependencies
# RUN /opt/scripts/install-apt.sh /opt/nebari-workflow-controller/apt.txt  

ARG SKIP_CONDA_SOLVE=no
COPY nebari-workflow-controller/environment.yaml /opt/nebari-workflow-controller/environment.yaml
RUN --mount=type=cache,target=/root/.cache/conda \
    --mount=type=cache,target=/opt/conda/pkgs \
    if [ "${SKIP_CONDA_SOLVE}" != "no" ];then  \
    ENV_FILE=/opt/nebari-workflow-controller/conda-linux-64.lock ; \
    else  \
    ENV_FILE=/opt/nebari-workflow-controller/environment.yaml ; \
    fi ; \
    /opt/scripts/install-conda-environment.sh "${ENV_FILE}" 'true'

COPY nebari-workflow-controller /opt/nebari-workflow-controller

CMD ["python", "-m", "nebari_workflow_controller"]
