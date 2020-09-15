# Docker images for MXNET
# How to use 

First make sure docker is installed. The docker plugin nvidia-docker is
required to run on Nvidia GPUs.

Step 1 :  Build Mxnet containers using below commands :
	  - For CPU Dockerfile run,
            "docker build -t mxnet/python:ubuntu_cpu ." or
            "docker build -t mxnet/python:rhel_cpu ."
	  - For GPU Dockerfile run,
            "nvidia-docker build -t mxnet/python:ubuntu_gpu ." or
            "nvidia-docker build -t mxnet/python:centos_gpu ."

Step 2 : The following command launches a container with the Python
         package installed.
	 - For CPU : "docker run -it mxnet/python:ubuntu_cpu" or
                     "docker run -it mxnet/python:rhel_cpu"
	 - For GPU :
	   If the host machine has at least one GPU installed and nvidia-docker
           is installed, i.e. if
           "nvidia-docker run --rm nvidia/cuda-ppc64le nvidia-smi" runs successfully,
           then you can run a container with GPU supports

	   $ "nvidia-docker run -it mxnet/python:ubuntu_gpu" or
             "nvidia-docker run -it mxnet/python:centos_gpu"

Step 3 : Then you can run MXNet in python, e.g.:

For CPU :
# python -c 'import mxnet as mx; a = mx.nd.ones((2,3)); print((a*2).asnumpy())'
[[ 2.  2.  2.]
 [ 2.  2.  2.]]

For GPU :
Now you can run the above example in GPU 0:
# python -c 'import mxnet as mx; a = mx.nd.ones((2,3), mx.gpu(0)); print((a*2).asnumpy())'
[[ 2.  2.  2.]
 [ 2.  2.  2.]]
