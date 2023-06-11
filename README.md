# Solar Gators Pit Build
## Building
1. Initialize the submodules `git submodule init`
1. Update the submodules `git submodule update`
1. Start the docker container `docker run --rm -it -v $PWD:/workdir crops/poky --workdir=/workdir`
1. Setup the build environment `source ./setup.sh`
1. Perform the build `./build.sh`
