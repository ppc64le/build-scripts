# Build ray-0.7.7

Please find the instructions to build ray-0.7.7 using python 3.7.3 on RHEL 7.6 below.

In order to build ray-0.7.7 using python 3.7.3, please copy the contents of current directory
to a directory on the build machine. Please ensure that build script and patches directory are
sibblings on the build machine.

Enable execute permissions for the build script and run it as:

```
# chmod +x pip-ray_0.7.7_rhel7.6.sh
# ./pip-ray_0.7.7_rhel7.6.sh
```

Please note that for executing test cases, some other dependecies like tensorflow, opencv-python
need to be built and installed. Also, some packages which are readily available for ppc64le need
to be installed using pip3.7. Please note that ray tests are CPU, memory exhaustive. So you need
to execute these tests on a high end VM. <= 3 of the following tests may fail (intel result is in
parity, failing tests differ over multiple runs):
  //python/ray/tests:test_stress
  //python/ray/tests:test_stress_failure
  //python/ray/tests:test_stress_sharded
  //python/ray/tests:test_debug_tools
  //python/ray/tests:test_basic
  //python/ray/tests:test_dynres
  //python/ray/tests:test_autoscaler_yaml
  //python/ray/tests:test_object_manager
  //python/ray/tests:test_multinode_failures

