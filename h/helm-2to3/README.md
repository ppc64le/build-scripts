#helm-2to3
The build script is created for the requested version v0.5.1 and for the requested verion v0.5.1
the build is passing but the test cases are failing as it required code changes in 
helm-2to3/pkg/v3/release.go file in line 206 we need to replaces "mapFiles" with "v2Files".
But this code changes are done in latest version that is v0.10.0 and with this changes 
in the latest version the build and test cases both are passing.
