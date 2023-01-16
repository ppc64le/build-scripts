#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-cpp
# Version       : v1.8.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage {Pratik.Tonage@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
 PACKAGE_NAME="opentelemetry-cpp"
 PACKAGE_VERSION=${1:-"v1.8.0"}
 PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-cpp"
 
 
# Install required dependencies
 yum install -y git cmake gcc-c++ libcurl-devel 

# Install GTest
 cd $HOME
 git clone https://github.com/google/googletest.git -b release-1.10.0
 cd googletest        
 mkdir build          
 cd build
 cmake ..   
 make 
 make install  

# Install benchmark
 cd $HOME
 git clone https://github.com/google/benchmark.git
 cd benchmark
# Make a build directory to place the build output.
 cmake -E make_directory "build"
# Generate build system files with cmake, and download any dependencies.
 cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../
# or, starting with CMake 3.13, use a simpler form:
# cmake -DCMAKE_BUILD_TYPE=Release -S . -B "build"
# Build the library.
 cmake --build "build" --config Release  
#run the test to check the build
 cmake -E chdir "build" ctest --build-config Release
#if want to install library globally,also run:
 cmake --build "build" --config Release --target install 


# Clone Repository
 cd ~
 mkdir source && cd source
 git clone --recursive -b $PACKAGE_VERSION https://github.com/open-telemetry/opentelemetry-cpp
 cd opentelemetry-cpp

# Build Opentelemetry
 mkdir build && cd build
 cmake ..
 cmake --build . --target all


# Install opentelemetry
 mkdir -p /opt/opentelemetry-cpp/
 cmake --install . --config Debug --prefix /opt/opentelemetry-cpp/

#After built Cmake tests run them with ctest command
 ctest

# copy binaries
 cp -R /opt/opentelemetry-cpp/ ../

# cleanup
 cd ..
 rm -rf opentelemetry-cpp/
