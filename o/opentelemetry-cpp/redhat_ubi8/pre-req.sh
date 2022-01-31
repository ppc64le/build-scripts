# --------------------------------------------------------------------------------
# Package       : opentelemetry-cpp
# Version       : v1.1.1
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : RHEL 8.5
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna H Voora <krishvoor@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# --------------------------------------------------------------------------------
#!/bin/bash

cd $HOME
git clone https://github.com/google/googletest.git -b release-1.11.0
cd googletest
mkdir build
cd build
cmake ..
make
make install
cd $HOME
git clone https://github.com/google/benchmark.git
cd benchmark
cmake -E make_directory "build"
cmake -DCMAKE_BUILD_TYPE=Release -S . -B "build"
cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../
cmake --build "build" --config Release
cmake -E chdir "build" ctest --build-config Release
cmake --build "build" --config Release --target install
