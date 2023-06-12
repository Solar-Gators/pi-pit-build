#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-h|i|V]"
   echo "options:"
   echo "h     Print this Help."
   echo "i     Image name."
   echo "v     Script version."
   echo
}

############################################################
# Set variables.                                           #
############################################################
SCRIPT_VERSION="1.0.0"
TARGET_IMAGE="core-image-base"
BITBAKE_ENV_FILE=".bbenv.tmp"

############################################################
# Process the input options.                               #
############################################################
# Get the options
while getopts ":hn:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Enter a name
         TARGET_IMAGE=$OPTARG;;
      v) # Print script version
         echo $SCRIPT_VERSION
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# Query the environment variables and redirect them to a file so we can grep
bitbake $TARGET_IMAGE -e 1> $BITBAKE_ENV_FILE
# Get some environment variables from the bitbake temp file
# Grep for the var we want, pass it to cut to get the value
TOP_DIR=$(grep ^TOP_DIR= $BITBAKE_ENV_FILE | cut -d'"' -f2)
DEPLOY_DIR_IMAGE=$(grep ^DEPLOY_DIR_IMAGE= $BITBAKE_ENV_FILE | cut -d'"' -f2)
SDKDEPLOYDIR=$(grep ^SDKDEPLOYDIR= $BITBAKE_ENV_FILE | cut -d'"' -f2)
SDKEXTDEPLOYDIR=$(grep ^SDKEXTDEPLOYDIR= $BITBAKE_ENV_FILE | cut -d'"' -f2)
IMAGE_MANIFEST=$(grep ^IMAGE_MANIFEST= $BITBAKE_ENV_FILE | cut -d'"' -f2)
MACHINE=$(grep ^MACHINE= $BITBAKE_ENV_FILE | cut -d'"' -f2)
IMAGE_BASENAME=$(grep ^IMAGE_BASENAME= $BITBAKE_ENV_FILE | cut -d'"' -f2)
IMAGE_NAME="$IMAGE_BASENAME-$MACHINE"
IMAGE_FSTYPES=$(grep ^IMAGE_FSTYPES= $BITBAKE_ENV_FILE | cut -d'"' -f2)
# Remove the temporary file
rm $BITBAKE_ENV_FILE

# Call the build script then we will do things with the output
./build.sh -i $TARGET_IMAGE -s -e

# Put the built image, sdk installer, and esdk installer in an archive
TIME_STAMP=`date +"%Y%m%d-%H%M%S"`

# Create the release folder structure
RELEASE_DIR="releases"
if [ ! -d "$RELEASE_DIR" ] ; then
    mkdir "$RELEASE_DIR"
fi
THIS_RELEASE_DIR="$RELEASE_DIR/release-$TIME_STAMP"
mkdir "$THIS_RELEASE_DIR"
mkdir "$THIS_RELEASE_DIR/images"
mkdir "$THIS_RELEASE_DIR/sdk"
mkdir "$THIS_RELEASE_DIR/esdk"

# Copy all the images created
for ext in $IMAGE_FSTYPES; do
    cp --dereference "$DEPLOY_DIR_IMAGE/$IMAGE_NAME.$ext" "$THIS_RELEASE_DIR/images"
done

# Copy the image information
cp --dereference "$DEPLOY_DIR_IMAGE/$IMAGE_NAME.testdata.json" "$THIS_RELEASE_DIR"
cp --dereference "$DEPLOY_DIR_IMAGE/$IMAGE_NAME.manifest" "$THIS_RELEASE_DIR"

# Copy the sdk
cp -a $SDKDEPLOYDIR/. "$THIS_RELEASE_DIR/sdk"

# Copy the esdk
cp -a $SDKEXTDEPLOYDIR/. "$THIS_RELEASE_DIR/esdk"

# Archive the release
pushd $RELEASE_DIR
    tar -czf "release-$TIME_STAMP.tgz" $THIS_RELEASE_DIR
popd

# All Done!
