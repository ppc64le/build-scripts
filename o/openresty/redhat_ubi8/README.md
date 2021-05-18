Build openresty/openresty
------------------------------------

Step 1)	Build openresty/openresty container image (once per release)
	$ docker build -t openresty_ibm .

Step 2) Build openresty/openresty

        Usage:
                $ docker run --rm -v `pwd`:/ws openresty_ibm bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # by default, build "lasttestedrelease" which is v1.19.3.1  marked as a 'Tagged'  as on 7 Nov 2020
                # both the commands below build the v1.19.3.1 branch
                $ docker run --rm -v `pwd`:/ws openresty_ibm bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
                $ docker run --rm -v `pwd`:/ws openresty_ibm bash -l -c "cd /ws; ./build.sh lasttestedrelease 2>&1 | tee output.log"

		===================
		Build and Run Tests
		===================
		# build last stable release and run test
		# at this point in time, the tests are failing on ppc64le
		$ docker run --rm -v `pwd`:/ws openresty_ibm bash -l -c "cd /ws; ./build.sh laststablerelease runtest 2>&1 | tee output.log"

		# build release "v1.19.3.1" and run tests
		$ docker run --rm -v `pwd`:/ws openresty_ibm bash -l -c "cd /ws; ./build.sh runtest 2>&1 | tee output.log"
