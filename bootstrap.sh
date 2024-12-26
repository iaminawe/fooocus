#!/bin/bash

set -e

repo_url="https://github.com/lllyasviel/Fooocus/archive/refs/tags/"
fooocus_version="v2.4.1"
fooocus_tar="/app/Fooocus/Fooocus-${fooocus_version}.tar.gz"

if [ ! -d "/app/Fooocus" ]; then
    mkdir -p /app/Fooocus
fi

if ! curl -fSL "${repo_url}${fooocus_version}.tar.gz" -o "${fooocus_tar}"; then
    echo "Failed to download Fooocus"
    exit 1
fi

if ! virtualenv /app/venv; then
    echo "Failed to create venv"
    exit 1
fi

# Create pip cache directory in the mounted volume
mkdir -p /app/Fooocus/pip_cache
export PIP_CACHE_DIR=/app/Fooocus/pip_cache
export TMPDIR=/app/Fooocus/tmp
mkdir -p "$TMPDIR"

cd /app/Fooocus
tar -xvf "${fooocus_tar}" --strip-components=1
rm -f "${fooocus_tar}"

source /app/venv/bin/activate

# Function to clean temporary files while preserving essential packages
cleanup() {
    find "$PIP_CACHE_DIR" -type f -name "*.whl" -mtime +1 -delete
    find "$PIP_CACHE_DIR" -type f -name "*.tar.gz" -mtime +1 -delete
    find "$TMPDIR" -type f -mtime +1 -delete
}

# Initial cleanup of any existing cache
cleanup

# Ensure base packages are installed first in the virtual environment
echo "Installing base packages..."
pip install --cache-dir="$PIP_CACHE_DIR" packaging
pip install --cache-dir="$PIP_CACHE_DIR" --upgrade "pip<24.1"

# Install numpy and torchsde separately first
echo "Installing numpy and torchsde..."
pip install --cache-dir="$PIP_CACHE_DIR" numpy>=1.19
pip install --cache-dir="$PIP_CACHE_DIR" torchsde==0.2.5

# Install remaining requirements with proper error handling
echo "Installing remaining requirements..."
grep -v "torchsde" /app/Fooocus/requirements_versions.txt > "$TMPDIR/requirements.txt"
if ! pip install --cache-dir="$PIP_CACHE_DIR" -r "$TMPDIR/requirements.txt"; then
    echo "Failed to install requirements"
    cleanup
    exit 1
fi

# Cleanup old cache files but keep recent ones
cleanup

# Verify packaging module is installed
python -c "import packaging" || pip install --no-cache-dir packaging

# Run the application with explicit host binding
exec python launch.py --listen --port 7865
