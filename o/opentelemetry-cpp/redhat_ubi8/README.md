Build/Test opentelemetry-cpp
----------------------------

Step 1) Build opentelemetry-cpp builder image (once per release)
	$ docker build -t opentelemetry-cpp-builder .

Step 2) Build/Test opentelemetry-cpp

        Usage:
                $ docker run --rm -v `pwd`:/ws opentelemetry-cpp-builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"


        Examples:
                ==========
                Build Only
                ==========
                # by default, build "lasttestedrelease" which is v1.1.1 marked as 'Latest_Release' as of 21 Dec 2021
                # both the commands below build the "v1.1.1: branch
                $ docker run --rm -v `pwd`:/ws opentelemetry-cpp-builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
                $ docker run --rm -v `pwd`:/ws opentelemetry-cpp-builder bash -l -c "cd /ws; ./build.sh lasttestedrelease 2>&1 | tee output.log"

                # to build master branch
                $ docker run --rm -v `pwd`:/ws opentelemetry-cpp-builder bash -l -c "cd /ws; ./build.sh master 2>&1 | tee output.log"

                # build specific branch/release
                $ docker run --rm -v `pwd`:/ws opentelemetry-cpp-builder bash -l -c "cd /ws; ./build.sh v1.1.1 2>&1 | tee output.log"
