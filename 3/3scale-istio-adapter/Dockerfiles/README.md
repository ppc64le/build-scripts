Build/Test 3scale-istio-adapter
-------------------------------
A 3scale-istio-adapter is an out of process gRPC Adapter which integrates 3scale with Istio


Step 1) Build 3scale-istio-adapter container image ( per GA release )
	`$ docker build -t 3scale-istio-adapter:ibm . `

Step 2) Build and Test 3scale-istio-adapter inside container image
Usage:
	        `docker run --rm -v `pwd`:/ws 3scale-istio-adapter:ibm bash -l -c "cd /ws; ./build.sh <rel_tag> <runtest> | tee output.log"`


Examples:
		==========
		Only Build
		==========
		### Builds last stable release by default, for specific release pass "laststablerelease". No Tests.
		$ docker run --rm -v `pwd`:/ws 3scale-istio-adapter:ibm bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
		$ docker run --rm -v `pwd`:/ws 3scale-istio-adapter:ibm bash -l -c "cd /ws; ./build.sh laststablerelease 2>&1 | tee output.log"

		### Build specific branch/release. No Tests
		$ docker run --rm -v `pwd`:/ws 3scale-istio-adapter:ibm bash -l -c "cd /ws; ./build.sh v0.18.1 2>&1 | tee output.log"
