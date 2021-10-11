Build/Test opentracing
-------------------------

Opentracing is open distributed tracing standard for applications and OSS packages.

Step 1) Build opentracing container image (once per release)
	$ docker build -t opentracing:ibm .

Step 2) Build and Test opentracing

	Usage:
		$ docker run --rm -v `pwd`:/ws opentracing:ibm bash -l -c "cd /ws; ./build.sh <rel_tag> <runtest> 2>&1 | tee output.log"
	Examples:
		==========
		Build & Run Tests
		==========
		# by default, build "master or main" or pass desired release to build as argument
		$ docker run --rm -v `pwd`:/ws opentracing:ibm bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

		# only 'runtest' passed - so build master branch & test
                $ docker run --rm -v `pwd`:/ws opentracing:ibm bash -l -c "cd /ws; ./build.sh runtest 2>&1 | tee output.log"

		# build specific branch/release. No tests
                $ docker run --rm -v `pwd`:/ws opentracing:ibm bash -l -c "cd /ws; ./build.sh v1.6.0 2>&1 | tee output.log"

		# build specific branch/release and run tests
		$ docker run --rm -v `pwd`:/ws opentracing:ibm bash -l -c "cd /ws; ./build.sh v1.6.0 runtest 2>&1 | tee output.log"
