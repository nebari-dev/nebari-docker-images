# nebari base Docker images

[![Build Docker Images](https://github.com/nebari-dev/nebari-docker-images/actions/workflows/build-push-docker.yaml/badge.svg)]

This repo contains the source code for Docker (container) images used by the Nebari platform. This repo also contains an automated means of building and pushing these images to public container registries. Currently these images are built and pushed to the following registries:

GitHub Container Registry (ghcr.io)

- [`nebari-jupyterlab`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterlab)
- [`nebari-jupyterhub`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterhub)
- [`nebari-dask-worker`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-dask-worker)

Quay Container Registry (quay.io)

- [`nebari-jupyterlab`](https://quay.io/repository/nebari/nebari-jupyterlab)
- [`nebari-jupyterhub`](https://quay.io/repository/nebari/nebari-jupyterhub)
- [`nebari-dask-worker`](https://quay.io/repository/nebari/nebari-dask-worker)

## Getting started

Whether you want to contribute to this project or simply wish use these images, to get started, fork this repo and then clone the forked repo onto your local machine.

### Pre-requisites

Currently the only pre-requisite is that you have [`docker` installed](https://docs.docker.com/get-docker/) on your local machine.

### Building Dockerfile

Assuming you are in the repo's root folder, you can build these images locally by running the listed commands on your terminal.

For JupyterLab

```shell
docker build -f Dockerfile.jupyterlab -t qhub-jupyterlab:latest .
```

For JupyterHub

```shell
docker build -f Dockerfile.dask-worker -t qhub-dask-worker:latest .
```

For Dask-Worker

```shell
docker build -f Dockerfile.dask-gateway -t qhub-dask-gateway:latest .
```

> **NOTE**
> It is extremely important to pin specific packages `dask-gateway` and `distributed` as they need to run the same version for the dask-workers to work as expected.

### Reporting an issue

If you encounter an issue, feel free to open an issue [here](https://github.com/nebari-dev/nebari-docker-images/issues/new/choose).

## License

TBD
