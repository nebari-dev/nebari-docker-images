# #!/usr/bin/env bash
# # Copyright (c) Nebari Development Team.
# # Distributed under the terms of the Modified BSD License.

# set -xe

# # Adding the packagecloud repository for git-lfs installation
# wget --quiet https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh
# expected_sum=5fc673f9a72b94c011b13eb5caedc3aa4541b5c5506b95d013cb7ba0f1cf66cf

# if [[ ! $(sha256sum script.deb.sh) == "${expected_sum}  script.deb.sh" ]]; then
#     echo Unexpected hash from git-lfs install script
#     exit 1
# fi

# # Install packagecloud's repository signing key and add repository to apt
# sh ./script.deb.sh

# # Install git-lfs
# apt-get install -y --no-install-recommends git-lfs
