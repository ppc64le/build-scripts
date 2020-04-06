Build Maistra/istio maistra-1.1
In order to build istio, please copy the contents of current directory to a directory on the build machine. 
Please ensure that build script and patches directory are placed in the same folder.

Note that the patches are for istio-proxy and istio build.

Enable execute permissions for the build script and run it as:

# chmod +x maistra_istio_rhel_7.6.sh
# ./maistra_istio_rhel_7.6.sh