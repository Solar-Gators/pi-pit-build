#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-h|i|v|s|e]"
   echo "options:"
   echo "h     Print this Help."
   echo "i     Image name."
   echo "v     Script version."
   echo "s     Build an SDK for this image."
   echo "e     Build an Extensible SDK for this image."
   echo
}

############################################################
# Set variables.                                           #
############################################################
SCRIPT_VERSION="1.0.0"
TARGET_IMAGE="core-image-base"
BUILD_SDK=false
BUILD_ESDK=false

############################################################
# Process the input options.                               #
############################################################
# Get the options
while getopts ":hi:vse" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Enter a name
         TARGET_IMAGE=$OPTARG;;
      v) # Print script version
         echo $SCRIPT_VERSION
         exit;;
      s)
         echo "Building SDK"
         BUILD_SDK=true;;
      e)
         echo "Building ESDK"
         BUILD_ESDK=true;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# Build the image
bitbake $TARGET_IMAGE
# Build the sdk
if [ "$BUILD_SDK" = true ] ; then
    bitbake $TARGET_IMAGE -c do_populate_sdk
fi
# Build the extensible sdk
if [ "$BUILD_ESDK" = true ] ; then
    bitbake $TARGET_IMAGE -c do_populate_sdk_ext
fi
