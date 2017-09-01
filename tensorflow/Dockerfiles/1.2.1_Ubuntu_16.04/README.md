nstructions for Tensorflow package.

NOTE - We are providing some patches in patches.zip file, please keep these patches and Dockerfile in the same directory
e.g.  $ cd <$wdir>
	     |
             |_ Dockerfile (This is TF Dockerfile)
	     |
             |-patches (All patches should be in "patches" directory)

1) First create a docker image using following command :
      
	$ docker build -t tensorflow .


2) Run tensorflow image & create container :

	$ docker run -it tensorflow /bin/bash

3) Run below command to check tensorflow1.2.1 installed location and other information
   
        $ pip show tensorflow


4) Try your first TensorFlow program

	$ python
	>>> import tensorflow as tf
	>>> hello = tf.constant('Hello, TensorFlow!')
	>>> sess = tf.Session()
	>>> sess.run(hello)
	'Hello, TensorFlow!'
	>>> a = tf.constant(10)
	>>> b = tf.constant(32)
	>>> sess.run(a + b)
	42
	>>> sess.close()


NOTE -  # This Dockerifle created to build TensorFlow with CPU support only. 
	# If you want to build with GPU support please follow below instructions - 
	  1) To build TF with GPU-enabled, first we need to install cuda and cudnn dependencies, 
	      please refer page http://www.nvidia.com/object/gpu-accelerated-applications-tensorflow-installation.html to install the same
	  2) Once installed run below commands

        git clone --recurse-submodules https://github.com/tensorflow/tensorflow && \
        cd tensorflow && \
        git checkout v1.2.1 && \
	patch -p1 < $wdir/patches/cast_op_test_ppc64le.patch && \
        patch -p1 < $wdir/patches/denormal_test_ppc.patch && \
        patch -p1 < $wdir/patches/larger-tolerence-in-linalg_grad_test.patch && \
        patch -p1 < $wdir/patches/platform_profile_utils_cpu_utils_test_ppc64le.patch && \
        patch -p1 < $wdir/patches/sparse_matmul_op_ppc.patch && \
        patch -p1 < $wdir/patches/update-highwayhash.patch && \
        export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8" && \
        export GCC_HOST_COMPILER_PATH=/usr/bin/gcc && \
        export PYTHON_BIN_PATH=/usr/bin/python && \
        export USE_DEFAULT_PYTHON_LIB_PATH=1 && \
        export TF_NEED_GCP=1 && \
        export TF_NEED_HDFS=1 && \
        export TF_NEED_JEMALLOC=1 && \
        export TF_ENABLE_XLA=1 && \
        export TF_NEED_OPENCL=0 && \
        export TF_NEED_CUDA=1 && \
 	export TF_CUDA_VERSION=8.0 && \
	export CUDA_TOOLKIT_PATH=/usr/local/cuda-8.0 && \
	export TF_CUDA_COMPUTE_CAPABILITIES=3.5,3.7,5.2,6.0 && \
	export CUDNN_INSTALL_PATH=/usr/local/cuda-8.0 && \
	export TF_NEED_VERBS=0 && \
	export TF_NEED_MKL=0 && \
	export TF_CUDNN_VERSION=5 && \
	./configure && \
        bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        pip install /tmp/tensorflow_pkg/tensorflow-1.2.1* && \
	export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH" && \
        bazel test --config=opt --config=cuda -k --jobs 1 //tensorflow/...  
