# Nebari base Docker images

| Information | Links                                                                                                                                                                                                                                                                                                                                                                |
| :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Project     | [![License - BSD3 License badge](https://img.shields.io/badge/License-BSD%203--Clause-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)](https://opensource.org/licenses/BSD-3-Clause) [![Nebari documentation badge - nebari.dev](https://img.shields.io/badge/%F0%9F%93%96%20Read-the%20docs-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)][nebari-docs] |
| Community   | [![GH discussions badge](https://img.shields.io/badge/%F0%9F%92%AC%20-Participate%20in%20discussions-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)][nebari-discussions] [![Open a GH issue badge](https://img.shields.io/badge/%F0%9F%93%9D%20Open-an%20issue-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)][nebari-docker-issues]                     |
| CI          | ![Build Docker Images - GitHub action status badge](https://github.com/nebari-dev/nebari-docker-images/actions/workflows/build-push-docker.yaml/badge.svg)                                                                                                                                                                                                           |

- [Nebari base Docker images](#nebari-base-docker-images)
  - [:zap: Getting started](#zap-getting-started)
    - [:computer: Prerequisites](#computer-prerequisites)
    - [:hammer_and_wrench: Building the Docker images](#hammer_and_wrench-building-the-docker-images)
    - [:broom: Pre-commit hooks](#broom-pre-commit-hooks)
  - [:pencil: Reporting an issue](#pencil-reporting-an-issue)
  - [:raised_hands: Contributions](#raised_hands-contributions)
  - [:page_facing_up: License](#page_facing_up-license)

This repository contains the source code for Docker (container) images used by the [Nebari platform][nebari-docs]. It also contains an automated means of building and pushing these images to public container registries through [GitHub actions][nebari-docker-actions]. Currently, these images are built and pushed to the following registries:

**GitHub Container Registry (ghcr.io)**

- [`nebari-jupyterlab`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterlab)
- [`nebari-jupyterhub`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterhub)
- [`nebari-dask-worker`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-dask-worker)

**Quay Container Registry (quay.io)**

- [`nebari-jupyterlab`](https://quay.io/repository/nebari/nebari-jupyterlab)
- [`nebari-jupyterhub`](https://quay.io/repository/nebari/nebari-jupyterhub)
- [`nebari-dask-worker`](https://quay.io/repository/nebari/nebari-dask-worker)

## :zap: Getting started

Whether you want to contribute to this project or whether you wish use these images, to get started, fork this repo and then clone the forked repo onto your local machine.

### :computer: Prerequisites

Currently, the only prerequisite is that you have [`docker` installed](https://docs.docker.com/get-docker/) on your local machine.

### :hammer_and_wrench: Building the Docker images

Assuming you are in the repo's root folder, you can build these images locally by running the listed commands on your terminal.

- For [JupyterLab](Dockerfile.jupyterlab):

```shell
docker build -f Dockerfile.jupyterlab \
    -t qhub-jupyterlab:latest .
```

- For [JupyterHub](Dockerfile.jupyterhub):

```shell
docker build -f Dockerfile.dask-worker \
    -t qhub-dask-worker:latest .
```

- For [Dask-Worker](Dockerfile.dask-worker):

```shell
docker build -f Dockerfile.dask-gateway \
    -t qhub-dask-gateway:latest .
```

> **NOTE**
> It is extremely important to pin specific packages `dask-gateway` and `distributed` as they need to run the same version for the `dask-workers` to work as expected.

### :broom: Pre-commit hooks

This repository uses the `prettier` pre-commit hook to standardize our YAML and markdown structure.
To install and run it, use these commands from the repository root:

```bash
# install the pre-commit hooks
pre-commit install

# run the pre-commit hooks
pre-commit run --all-files
```

## :pencil: Reporting an issue

If you encounter an issue or want to make suggestions on how we can make this project better, feel free to [open an issue on this repository's issue tracker](https://github.com/nebari-dev/nebari-docker-images/issues/new/choose).

## :raised_hands: Contributions

Thinking about contributing to this repository or any other in the Nebari org? Check out our
[Contribution Guidelines](https://github.com/nebari-dev/nebari/blob/main/CONTRIBUTING.md).

## :page_facing_up: License

[Nebari is BSD3 licensed](LICENSE).

<!-- Links -->

[nebari-docker-repo]: https://github.com/nebari-dev/nebari-docker-images
[nebari-docker-issues]: https://github.com/nebari-dev/nebari-docker-images/issues/new/choose
[nebari-docker-actions]: https://github.com/nebari-dev/nebari-docker-images/actions
[nebari-discussions]: https://github.com/orgs/nebari-dev/discussions
[nebari-docs]: https://nebari.dev
