#!/usr/bin/env bash
# Copyright (c) Nebari Development Team.
# Distributed under the terms of the Modified BSD License.

set -xe
DEFAULT_PREFIX="${1}"
shift # path to environment yaml or lock file
CODE_SERVER_VERSION=4.104.3

mkdir -p ${DEFAULT_PREFIX}/code-server
cd ${DEFAULT_PREFIX}/code-server

# Fetch the snapshot of https://code-server.dev/install.sh as of the time of writing
wget --quiet https://raw.githubusercontent.com/coder/code-server/v4.104.3/install.sh
expected_sum=e86784e9fec81106c74941e55dbbcb85dc963a06ad6c3f1a870d4a22cf432e1d

if [[ ! $(sha256sum install.sh) == "${expected_sum}  install.sh" ]]; then
    echo Unexpected hash from code-server install script
    exit 1
fi

mkdir /opt/tmpdir
sh ./install.sh --method standalone --prefix /opt/tmpdir --version ${CODE_SERVER_VERSION}

mv /opt/tmpdir/lib/code-server-${CODE_SERVER_VERSION}/* ${DEFAULT_PREFIX}/code-server
rm -rf /opt/tmpdir
