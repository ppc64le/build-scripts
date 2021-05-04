Build KeyCloak Init/Server Containers
--------------------------------------

Keycloak is an Open Source Identity and Access Management solution for modern Applications and Services.

Step 1) Build KeyCloak Init/Server container image (once per release)

	Usage:
		==========
		Build Only
		==========
		# build last stable release by default or pass "laststablerelease". No tests
		$ ./build.sh 2>&1 | tee output.log
		$ ./build.sh laststablerelease 2>&1 | tee output.log
For More information on usuage https://github.com/keycloak/keycloak-containers/tree/master/keycloak-init-container#keycloak--rhsso-extensions-init-container
