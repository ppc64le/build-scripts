In the requested version (v0.5.3), build is ignored (disabled) in file "ext_dep_test.go" using below line.

  // //+build ignore

To build and test requested version we need to make code change (Uncomment above line), that would require OSSC approval.

This change is not required in latest release version (v1.1.5), and I have created below build script to build and test version v1.1.5.

  go-msgpack_v1.1.5_ubi8.4.sh

