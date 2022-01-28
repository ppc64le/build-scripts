Build/Test 3scale_toolbox
-------------------------

3scale toolbox is a set of tools to help manage 3scale product.

Step 1) Build 3scale_toolbox builder image (once per release)
	$ docker build -t 3scale_toolbox_builder .

Step 2) Build and Test 3scale_toolbox. 

	Usage:
		$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh <rel_tag> <runtest> 2>&1 | tee output.log"

	Examples:
		==========
		Build Only
		==========
		# build last stable release by default or pass "laststablerelease". No tests
		$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
		$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh laststablerelease 2>&1 | tee output.log"

		# build specific branch/release. No tests
		$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh v0.18.1 2>&1 | tee output.log"


		===================
		Build and Run Tests
		===================
		# build last stable release and run test
		$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh laststablerelease runtest 2>&1 | tee output.log"

		# build release "v0.18.1" and run tests
		$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh v0.18.1 runtest 2>&1 | tee output.log"
