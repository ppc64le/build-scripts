# Build istio 1.14.3

In order to build istio, please copy the contents of current directory to a directory
on the build machine. Please ensure that build script and patches directory are sibblings on
the build machine.

Note that the patches are for istio-proxy build which is a dependency for istio build.

Enable execute permissions for the build script and run it as:

```
# chmod +x istio_rhel7.6.sh
# ./istio_rhel7.6.sh
```
