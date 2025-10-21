<p align="center">
<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/nebari-dev/nebari-design/main/logo-mark/horizontal/Nebari-Logo-Horizontal-Lockup.svg">
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/nebari-dev/nebari-design/main/logo-mark/horizontal/Nebari-Logo-Horizontal-Lockup-White-text.svg">
  <img alt="Nebari logo mark - text will be black in light color mode and white in dark color mode." src="https://raw.githubusercontent.com/nebari-dev/nebari-design/main/logo-mark/horizontal/Nebari-Logo-Horizontal-Lockup-White-text.svg" width="50%"/>
</picture>
</p>

---

# Nebari Base Docker Images: A Verse

| Information | Links                                                                                                                                                                                                                                                                                                                                                                |
| :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Project     | [![License - BSD3 License badge](https://img.shields.io/badge/License-BSD%203--Clause-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)](https://opensource.org/licenses/BSD-3-Clause) [![Nebari documentation badge - nebari.dev](https://img.shields.io/badge/%F0%9F%93%96%20Read-the%20docs-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)][nebari-docs] |
| Community   | [![GH discussions badge](https://img.shields.io/badge/%F0%9F%92%AC%20-Participate%20in%20discussions-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)][nebari-discussions] [![Open a GH issue badge](https://img.shields.io/badge/%F0%9F%93%9D%20Open-an%20issue-gray.svg?colorA=2D2A56&colorB=5936D9&style=flat.svg)][nebari-docker-issues]                     |
| CI          | ![Build Docker Images - GitHub action status badge](https://github.com/nebari-dev/nebari-docker-images/actions/workflows/build-push-docker.yaml/badge.svg)                                                                                                                                                                                                           |

## Contents

- [Of Docker Images Base](#of-docker-images-base)
- [To Start Upon This Journey Fair](#to-start-upon-this-journey-fair)
  - [What Tools Thou Needs Before Thee Start](#what-tools-thou-needs-before-thee-start)
  - [To Build These Images With Thine Hands](#to-build-these-images-with-thine-hands)
  - [Of Hooks That Clean Before Commit](#of-hooks-that-clean-before-commit)
- [To Tell Us Of A Problem Found](#to-tell-us-of-a-problem-found)
- [Of Those Who Wish To Contribute](#of-those-who-wish-to-contribute)
- [The License Under Which We Work](#the-license-under-which-we-work)

## Of Docker Images Base

Within this vault of code there lies the source
Of Docker images that Nebari employs.
By automated means and GitHub's force,
These containers build and push, with little noise,
To registries where all the world may see
And pull them down to use in their own way.
In GitHub's realm and Quay they stored shall be,
Awaiting those who need them night or day.

**In GitHub's Container Registry:**

- [`nebari-jupyterlab`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterlab)
- [`nebari-jupyterlab-gpu`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterlab-gpu)
- [`nebari-jupyterhub`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-jupyterhub)
- [`nebari-dask-worker`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-dask-worker)
- [`nebari-dask-worker-gpu`](https://github.com/orgs/nebari-dev/packages/container/package/nebari-dask-worker-gpu)

**In Quay's Container Registry:**

- [`nebari-jupyterlab`](https://quay.io/repository/nebari/nebari-jupyterlab)
- [`nebari-jupyterlab-gpu`](https://quay.io/repository/nebari/nebari-jupyterlab-gpu)
- [`nebari-jupyterhub`](https://quay.io/repository/nebari/nebari-jupyterhub)
- [`nebari-dask-worker`](https://quay.io/repository/nebari/nebari-dask-worker)
- [`nebari-dask-worker-gpu`](https://quay.io/repository/nebari/nebari-dask-worker-gpu)

## To Start Upon This Journey Fair

If thou wouldst join our cause or use these works,
Then fork this repo first, as is the way,
And clone it to thy machine where it lurks,
Upon thy local disk it there shall stay.

### What Tools Thou Needs Before Thee Start

Before thou dost begin this noble task,
Two tools must grace thy system, I do ask:

- [`docker`](https://docs.docker.com/get-docker/) must be installed with care,
  The docs shall guide thee through this whole affair.
- [pre-commit](https://pre-commit.com/) hooks must also be in place,
  Install with pip or conda, take thy space:

  ```bash
  pip install pre-commit
  # or using conda
  conda install -c conda-forge pre-commit
  ```

### To Build These Images With Thine Hands

From repository root, as thou shalt see,
These images may be built quite easily.
Upon thy terminal run commands clear,
And Docker images shall soon appear.

- To build the lab where Jupyter dwells:

  ```shell
  make jupyterlab
  ```

- To build the hub where users come to rest:

  ```shell
  make jupyterhub
  ```

- To build the workers who compute with speed:

  ```shell
  make dask-worker
  ```

- To build the controller of the flow:

  ```shell
  make workflow-controller
  ```

- To build them all in one fell swoop complete:

  ```shell
  make all
  ```

- To cast away what thou hast built before:

  ```shell
  make clean
  ```

> **HARK! A WARNING MOST IMPORTANT HERE**
>
> The packages `dask-gateway` and `distributed` too,
> Must match in version, this is very clear,
> Or else thy dask-workers shall not push through.

### Of Hooks That Clean Before Commit

This repository doth employ with pride
The `prettier` hook to standardize our ways.
To install and run it, let this be thy guide,
These commands shall serve thee well through all thy days:

```bash
# install the pre-commit hooks
pre-commit install

# run the pre-commit hooks
pre-commit run --all-files
```

## To Tell Us Of A Problem Found

If thou shouldst find a bug or have a thought
On how to make this project better still,
Feel free to tell us what thy mind has wrought,
And [open up an issue](https://github.com/nebari-dev/nebari-docker-images/issues/new/choose) at thy will.

## Of Those Who Wish To Contribute

Art thou considering to join our band
And contribute to Nebari's grand design?
Then read our [Contribution Guidelines](https://nebari.dev/community) and understand
The ways in which thy work with ours shall align.

## The License Under Which We Work

[Know that Nebari is BSD3 licensed](LICENSE), friend,
And under this our code is freely shared,
That all may use and modify and send
Improvements back, for which we all have cared.

<!-- Links -->

[nebari-docker-repo]: https://github.com/nebari-dev/nebari-docker-images
[nebari-docker-issues]: https://github.com/nebari-dev/nebari-docker-images/issues/new/choose
[nebari-docker-actions]: https://github.com/nebari-dev/nebari-docker-images/actions
[nebari-discussions]: https://github.com/orgs/nebari-dev/discussions
[nebari-docs]: https://nebari.dev
