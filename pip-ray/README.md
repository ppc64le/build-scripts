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

Please note that the test case execution is not a part of the build script yet. For executing test
cases, some other dependecies like tensorflow, opencv-python, opencv-python-headless have to be built
and installed. Also, some packages which are readily available for ppc64le need to be installed using
pip3.7. The test case execution and debugging is currently in progress.
