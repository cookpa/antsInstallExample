#!/bin/bash

antsBuildInstructions="https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS"

# Number of threads used by make
buildThreads=4

echo "
This script will download ANTs, build and install under the current directory. 

Developer tools including compilers, git and cmake must be installed. 

This script will attempt to build with $buildThreads threads. If your processor, RAM
or swap space are limited, try building with a single thread.

If you encounter errors, please see the installation instructions at

  $antsBuildInstructions

Build will proceed in 8 seconds
"

sleep 8

workingDir=${PWD}

# Clone the repo
git clone https://github.com/ANTsX/ANTs.git

# If you want to build a particular release, do so here
# cd ANTs
# git checkout v2.3.1
# cd -

# Where to build, should be an empty directory
buildDir=${workingDir}/build
installDir=${workingDir}/install

mkdir $buildDir $installDir

cd $buildDir

# USE_VTK must be turned on to build antsSurf
#
# CMake may incorrectly detect the CPU architecture on Apple Silicon machines
# This is reported in the logs as "Arch detected: 'x86_64'"
# If you see this and the subsequent error "unknown target CPU", 
# add -DCMAKE_OSX_ARCHITECTURES=arm64 to the call below
cmake \
    -DCMAKE_INSTALL_PREFIX=$installDir \
    -DBUILD_SHARED_LIBS=OFF \
    -DUSE_VTK=OFF \
    -DBUILD_TESTING=OFF \
    -DRUN_LONG_TESTS=OFF \
    -DRUN_SHORT_TESTS=OFF \
    ${workingDir}/ANTs 2>&1 | tee cmake.log

if [[ $? -ne 0 ]]; then
  echo "ANTs SuperBuild configuration failed. Please review documentation at

    $antsBuildInstructions

  If opening an issue, please attach
  
  ${buildDir}/cmake.log
  ${buildDir}/CMakeCache.txt
  ${buildDir}/CMakeFiles/CMakeError.log
  ${buildDir}/CMakeFiles/CMakeOutput.log
  
"
  exit 1 
fi

make -j $buildThreads 2>&1 | tee build.log

if [[ ! -f "CMakeFiles/ANTS-complete" ]]; then
  echo "ANTs compilation failed. Please review documentation at

    $antsBuildInstructions

  If opening an issue, please attach

  ${buildDir}/build.log
  ${buildDir}/cmake.log
  ${buildDir}/CMakeCache.txt
  ${buildDir}/CMakeFiles/CMakeError.log
  ${buildDir}/CMakeFiles/CMakeOutput.log
  
"
  exit 1
fi

cd ANTS-build
make install 2>&1 | tee install.log

antsRegExe="${installDir}/bin/antsRegistration"

if [[ ! -f ${antsRegExe} ]]; then
  echo "Installation failed. Please review documentation at

    $antsBuildInstructions

  If opening an issue, please attach

  ${buildDir}/build.log
  ${buildDir}/cmake.log
  ${buildDir}/CMakeCache.txt
  ${buildDir}/ANTS-build/install.log
  ${buildDir}/CMakeFiles/CMakeError.log
  ${buildDir}/CMakeFiles/CMakeOutput.log

  and mention that you used this script with build command:

    make -j $buildThreads

"
  exit 1
fi

echo "Installation complete, running ${antsRegExe}"

${antsRegExe} --version

echo "
Binaries and scripts are located in 

  $installDir

Please see post installation instructions at 

  $antsBuildInstructions

"
