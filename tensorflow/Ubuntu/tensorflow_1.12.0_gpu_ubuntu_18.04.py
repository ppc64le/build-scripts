#!/usr/bin/env python
# ----------------------------------------------------------------------------
#
# Package       : TensorFlow
# Version       : v1.12.0
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : docker.io/nvidia/cuda-ppc64le:10.0-cudnn7-devel-ubuntu18.04
#                  docker container
# Script License: Apache License, Version 2 or later
# Maintainer    : William Irons <wdirons@us.ibm.com>
#
# Disclaimer: This script has been tested on given docker container
# ==========  using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Build script for TensorFlow 1.12.0 with GPU support on PPC64LE
# Run from within the docker container: docker.io/nvidia/cuda-ppc64le:10.0-cudnn7-devel-ubuntu18.04

# To run this script
# apt-get update -y
# apt-get install -y python
# python tensorflow_1.12.0_gpu_ubuntu_18.04.py

# The resulting wheel file will be in the tensorflow_pkg subdirectory from where the script was invoked.


import os.path, sys, subprocess
from subprocess import check_call, CalledProcessError


packages = [
    'apt-get install -y --no-install-recommends \
      openjdk-8-jdk \
      wget \
      curl \
      unzip \
      zip \
      git \
      rsync \
      python-dev \
      swig \
      python-numpy \
      libopenblas-dev \
      libcurl3-dev \
      libfreetype6-dev \
      libzmq3-dev \
      libhdf5-dev \
      g++ \
      patch \
      python-pip \
      python-setuptools \
      python-wheel \
      python-enum34',
    'pip install mock cython',
    'cp /usr/lib/powerpc64le-linux-gnu/hdf5/serial/libhdf5.so /usr/local/lib',
    'pip install --global-option=build_ext \
                 --global-option=-I/usr/include/hdf5/serial/ \
                 --global-option=-L/usr/lib/powerpc64le-linux-gnu/hdf5/serial \
                 h5py',
    'pip install keras_applications==1.0.6 keras_preprocessing==1.0.5 --no-deps'
    ]
# In the Ubuntu images, cudnn is placed in system paths. Move them to
# /usr/local/cuda
cudnn = [
    'cp -P /usr/include/cudnn.h /usr/local/cuda/include',
    'cp -P /usr/lib/powerpc64le-linux-gnu/libcudnn.so /usr/local/cuda/lib64',
    'cp -P /usr/lib/powerpc64le-linux-gnu/libcudnn.so.7 /usr/local/cuda/lib64',
    'cp -P /usr/lib/powerpc64le-linux-gnu/libcudnn.so.7.3.1 /usr/local/cuda/lib64',
    'cp -P /usr/lib/powerpc64le-linux-gnu/libcudnn_static.a /usr/local/cuda/lib64',
    'cp -P /usr/lib/powerpc64le-linux-gnu/libcudnn_static_v7.a /usr/local/cuda/lib64',
    ]
nccl = [
    'rm -rf nccl',
    'git clone -b v2.3.5-5 https://github.com/NVIDIA/nccl',
    'make -C nccl -j src.build NVCC_GENCODE=\"-gencode=arch=compute_70,code=sm_70\"',
    'make -C nccl pkg.txz.build',
    'tar xvf nccl/build/pkg/txz/nccl_2.3.5-5+cuda10.0_ppc64le.txz',
    'cp ./nccl_2.3.5-5+cuda10.0_ppc64le/include/nccl.h /usr/local/cuda/include',
    'mkdir -p /usr/local/cuda/lib',
    'cp ./nccl_2.3.5-5+cuda10.0_ppc64le/lib/libnccl.so /usr/local/cuda/lib',
    'cp ./nccl_2.3.5-5+cuda10.0_ppc64le/lib/libnccl.so.2 /usr/local/cuda/lib',
    'cp ./nccl_2.3.5-5+cuda10.0_ppc64le/lib/libnccl.so.2.3.5 /usr/local/cuda/lib',
    'cp ./nccl_2.3.5-5+cuda10.0_ppc64le/lib/libnccl_static.a /usr/local/cuda/lib',
    'chmod a+r /usr/local/cuda/include/',
    'chmod a+r /usr/local/cuda/lib/',
    'ldconfig'
]
bazel = [
    'mkdir -p bazel',
    'wget https://github.com/bazelbuild/bazel/releases/download/0.18.0/bazel-0.18.0-dist.zip',
    'mv bazel-0.18.0-dist.zip bazel/',
    'unzip -o bazel/bazel-0.18.0-dist.zip -d bazel/',
    'bazel/compile.sh',
    'cp bazel/output/bazel /usr/local/bin/'
    ]
git = [
    'rm -rf tensorflow',
    'git clone -b v1.12.0 https://github.com/tensorflow/tensorflow',
    ]

def run_cmd(command):

    '''
    Run the given command using check_call and verify its return code.
    @param str command command to be executed
    '''

    try:
        check_call(command.split())
    except CalledProcessError as e:
        if command.split()[0] == "rpm": 
            print('Ignore rpm failure, package is probably already installed')
        else:
            print('An exception has occurred: {0}'.format(e))
            sys.exit(1)

def execute_cmd(list, step):

    '''
    Execute the given commands using run_cmd function
    @param list list commands to be executed
    @param step str name of the comand to be executed
    '''

    print('Step: %s' % (step))
    
    for item in list:
        run_cmd(item)

def set_environment():

    '''
    Create bazelrc file with the necessary settings
    Note: Limiting TF_CUDA_COMPUTE_CAPABILITIES to only
    GPUs you plan to use will speed build time and decrease
    overall install size. See https://developer.nvidia.com/cuda-gpus
    for GPU model to Compute Capabilities mapping.
    '''

    f= open('tensorflow/.bazelrc',"w+")
    f.write("build --action_env PYTHON_BIN_PATH='/usr/bin/python'\n\
build --action_env PYTHON_LIB_PATH='/usr/local/lib/python2.7/site-packages'\n\
build --python_path='/usr/bin/python'\n\
build:xla --define with_xla_support=false\n\
build --action_env TF_NEED_OPENCL_SYCL='0'\n\
build --action_env TF_NEED_CUDA='1'\n\
build --action_env TF_CUDA_VERSION='10.0'\n\
build --action_env CUDA_TOOLKIT_PATH='/usr/local/cuda-10.0'\n\
build --action_env CUDNN_INSTALL_PATH='/usr/local/cuda-10.0'\n\
build --action_env NCCL_INSTALL_PATH='/usr/local/cuda-10.0/lib'\n\
build --action_env NCCL_HDR_PATH='/usr/local/cuda-10.0/targets/ppc64le-linux/include/'\n\
build --action_env TF_CUDNN_VERSION='7'\n\
build --action_env TF_NCCL_VERSION='2'\n\
build --action_env TF_CUDA_COMPUTE_CAPABILITIES='3.5,3.7,5.2,6.0,7.0'\n\
build --action_env LD_LIBRARY_PATH='/usr/local/nvidia/lib:/usr/local/nvidia/lib64'\n\
build --action_env TF_CUDA_CLANG='0'\n\
build --action_env GCC_HOST_COMPILER_PATH='/usr/bin/gcc'\n\
build --config=cuda\n\
test --config=cuda\n\
build:opt --copt=-mcpu=power8\n\
build:opt --copt=-mtune=power8\n\
build:opt --define with_default_optimizations=true\n\
build --strip=always\n\
build --spawn_strategy=standalone")
    f.close() 

def run_build(list, dir):
    '''
    Execute the given commands in other directory
    @param list list commands to be executed
    @param dir str directory path
    '''
    build = subprocess.Popen(list, cwd=dir)
    build.wait()
    if not build.returncode==0:
        print('Exiting due to failure in command: {0}'.format(list))
        sys.exit(1)

def main():
    execute_cmd(packages, 'Intalling necessary Packages')
    execute_cmd(cudnn, 'Moving cudnn files')
    execute_cmd(nccl, 'Installing nccl')
    execute_cmd(bazel, 'Installing bazel')
    execute_cmd(git, 'Cloning tensorflow')
    set_environment()

    run_build(['/usr/local/bin/bazel', 'build', '-c', 'opt', '//tensorflow/tools/pip_package:build_pip_package'], './tensorflow/')

    run_build(['bazel-bin/tensorflow/tools/pip_package/build_pip_package', '../tensorflow_pkg'], './tensorflow/')

    run_build(['pip', 'install', 'tensorflow-1.12.0-cp27-cp27mu-linux_ppc64le.whl'], './tensorflow_pkg/')

if __name__ == "__main__":
    main()
