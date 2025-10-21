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

# Create a directory for builtin extensions (read-only, can only be disabled by users)
mkdir -p /opt/code-server/builtin-extensions

# Define builtin extensions to install
BUILTIN_EXTENSIONS=(
  "ms-python.python"
)

# Build install flags
INSTALL_FLAGS=()
for extension in "${BUILTIN_EXTENSIONS[@]}"; do
  INSTALL_FLAGS+=(--install-extension "$extension")
done

# Install all builtin extensions in one command
if ! ${DEFAULT_PREFIX}/code-server/bin/code-server \
  --extensions-dir /opt/code-server/builtin-extensions \
  "${INSTALL_FLAGS[@]}"; then
  echo "ERROR: Failed to install one or more extensions"
  exit 1
fi

# Create a wrapper script that adds the --builtin-extensions-dir flag
mv ${DEFAULT_PREFIX}/code-server/bin/code-server ${DEFAULT_PREFIX}/code-server/bin/code-server-original

cat > ${DEFAULT_PREFIX}/code-server/bin/code-server << 'EOF'
#!/usr/bin/env bash
# Wrapper script to automatically include builtin extensions
exec "$(dirname "$0")/code-server-original" --builtin-extensions-dir /opt/code-server/builtin-extensions "$@"
EOF

chmod +x ${DEFAULT_PREFIX}/code-server/bin/code-server
