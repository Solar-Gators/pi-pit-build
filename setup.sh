#!/bin/bash

############################################################
# Set variables.                                           #
############################################################
SCRIPT_VERSION="1.0.0"
# Get the directory that the script resides in
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WSL=false
BUILD_CONTAINER="crops/poky"
BASE_CONTAINER="ubuntu-22.04"

# Determine if we are running on WSL
if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
    echo 'Running in WSL'
    WSL=true
fi

# Make sure all submodules are setup and up to date
# Check if any submodules are uninitialized
uninitialized_submodules=$(git submodule status | grep -E '^[-]|^[+]' | awk '{print $2}')

# If there are uninitialized submodules, initialize/update them
if [ -n "$uninitialized_submodules" ]; then
  echo "Initializing/updating submodules:"
  echo "$uninitialized_submodules"
  git submodule update --init --recursive
else
  echo "All submodules are initialized and up to date."
fi

if [ "$WSL" = true ] ; then
    echo 'Running on WSL unable to determine docker deamon status'
else
    # Check if Docker is running
    if [ systemctl is-active --quiet docker ] ; then
        echo 'Docker is already running.'
    else
        # Start Docker using systemd
        sudo systemctl start docker

        # Check if Docker started successfully
        if [ systemctl is-active --quiet docker ] ; then
            echo 'Docker has been started successfully.'
        else
            echo 'Failed to start Docker.'
            exit 1
        fi
    fi
fi

# Build the docker container if it doesn't exist
if docker images --format '{{.Repository}}:{{.Tag}}' | grep "^$BUILD_CONTAINER:$BASE_CONTAINER$" >/dev/null; then
    echo "Image '$BUILD_CONTAINER:$BASE_CONTAINER' exists in the local repository"
else
    echo "Building '$BUILD_CONTAINER:$BASE_CONTAINER'"
    docker build \
        --build-arg BASE_DISTRO=${BASE_CONTAINER} \
        --pull -t ${BUILD_CONTAINER}:${BASE_CONTAINER} .
fi

docker run --rm -it \
    --workdir=/workdir \
    -v $SCRIPT_DIR:/workdir \
    ${BUILD_CONTAINER}:${BASE_CONTAINER}
