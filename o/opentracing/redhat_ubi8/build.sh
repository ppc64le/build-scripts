# ----------------------------------------------------------------------------
# Package       : opentracing
# Version       : 1.6.0
# Source repo   : https://github.com/opentracing/opentracing-cpp
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna Harsha Voora
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

#!/bin/bash
# clone branch/release passed as argument, if none, use master

runtest=0

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


# Clone Repository
cd $HOME/
(git clone $BRANCH https://github.com/opentracing/opentracing-cpp) || (echo "git clone failed" && exit $?)
cd opentracing-cpp
mkdir -p build; cd build

# make
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON ..
make
cd ..
bazel build //...

# run tests if "runtest" is passed as argument
if [ $runtest == 1 ]
then
	cd build/
	make test
	cd ../
	bazel test //...
fi

# Copy the artefacts out
tar -cf bazel-bin.tar ./bazel-bin/*
mv bazel-bin.tar /ws/

# Clean Up
cd $HOME/
rm -rf $HOME/opentracing-cpp/
