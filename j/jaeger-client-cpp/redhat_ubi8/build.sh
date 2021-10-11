# ----------------------------------------------------------------------------
# Package       : jaeger-client-cpp
# Version       : master
# Source repo   : https://github.com/jaegertracing/jaeger-client-cpp
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijit Mane <abhijman@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

#!/bin/bash

runtest=0

# clone branch/release passed as argument, if none, use master
case "$1" in
		   # no branch supplied, master is used
	"")	   BRANCH=""
		   ;;

	"runtest") BRANCH=""
		   runtest=1
		   ;;

	*)	   BRANCH="--branch $1"
		   if [ "$2" == "runtest" ]
		   then
			runtest=1
     		   fi
		   ;;
esac

echo "BRANCH = $BRANCH"

(git clone $BRANCH https://github.com/jaegertracing/jaeger-client-cpp) || { echo "git clone $BRANCH failed" && exit $?; }
cd jaeger-client-cpp

# build
mkdir build && cd build
cmake ..
make

# run tests if "runtest" is passed as argument
if [ $runtest == 1 ]
then
	echo "Running tests..."
	make test

	echo "Post build, run example C++ program available at: -"
	echo "https://github.com/jaegertracing/jaeger-client-cpp/blob/master/examples/App.cpp"
	./app ../examples/config.yml
fi

# copy artifacts
# current path: /`pwd`/jaeger-client-cpp/build
(tar cvf ../../build.tar --exclude='*.o' ../build) || { echo "tar of build artifacts failed" && exit $?; }
echo "build.tar containing build artifacts created"
ls -ld ../../build.tar

# cleanup
cd ../../
rm -rf jaeger-client-cpp
