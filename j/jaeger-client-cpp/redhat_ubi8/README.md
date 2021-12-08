Build/Test jaeger-client-cpp
----------------------------

Step 1) Build jaeger-client-cpp builder image (once per release)
        $ docker build -t jaeger-client-cpp-builder .

Step 2) Build/Test jaeger-client-cpp-builder

	Note: Tests can be run as any non-root user. In the Dockerfile used, a user 'appuser' is created. 
	      Ensure dir from which build/tests are launched has write permissions

        Usage:
                $ docker run --rm -v `pwd`:/ws jaeger-client-cpp-builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                =================
                Build & Run tests
                =================
                # by default, build "master or main" or pass desired release to build as argument
                $ docker run --rm -v `pwd`:/ws jaeger-client-cpp-builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

                # only 'runtest' passed - so build master branch & test
                $ docker run --rm -v `pwd`:/ws jaeger-client-cpp-builder bash -l -c "cd /ws; ./build.sh runtest 2>&1 | tee output.log"


                # build specific branch/release, no tests are run
                $ docker run --rm -v `pwd`:/ws jaeger-client-cpp-builder bash -l -c "cd /ws; ./build.sh v0.7.0 2>&1 | tee output.log"

                # build specific branch/release and run tests
                $ docker run --rm -v `pwd`:/ws jaeger-client-cpp-builder bash -l -c "cd /ws; ./build.sh v0.7.0 runtest 2>&1 | tee output.log"
