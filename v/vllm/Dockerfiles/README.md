############################ VLLM DOCKER IMAGE ################################

The docker file `Dockerfile.ppc64le` is used to build an image of vllm which is published
to `icr.io/ppc64le-oss/vllm-ppc64le:0.18.0`.

## Steps to build your own image

Clone the source code of vllm from https://github.com/vllm-project/vllm. The `build_vllm_ppc64le.sh` and `Dockerfile.ppc64le` are to be put into vllm's source code at its root directory in order to build the docker image.
To build the docker image, use `podman build -t vllm:<version> -f Dockerfile.ppc64le`. 

Note: The script and Dockerfile being commited in this commit may not always work with any vllm version, as many python dependencies are being built from source or fetched from pypi.org or IBM's devpi index. 
