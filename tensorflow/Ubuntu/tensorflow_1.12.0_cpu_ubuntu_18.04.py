#!/usr/bin/env python
# ----------------------------------------------------------------------------
#
# Package       : TensorFlow
# Version       : v1.12.0
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : ubuntu18.04 docker container
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
#
# Disclaimer: This script has been tested on given docker container
# ==========  using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Build script for TensorFlow 1.12.0 with CPU support on PPC64LE
# Run from within the docker container: ubuntu18.04

# To run this script
# apt-get update -y
# apt-get install -y python
# python tensorflow_1.12.0_cpu_ubuntu_18.04.py

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
    '''

    f= open('tensorflow/.bazelrc',"w+")
    f.write("build --action_env PYTHON_BIN_PATH='/usr/bin/python'\n\
build --action_env PYTHON_LIB_PATH='/usr/local/lib/python2.7/site-packages'\n\
build --python_path='/usr/bin/python'\n\
build:xla --define with_xla_support=false\n\
build --action_env TF_NEED_OPENCL_SYCL='0'\
build --action_env TF_NEED_CUDA='0'\n\
build --action_env TF_CUDA_CLANG='0'\n\
build --action_env GCC_HOST_COMPILER_PATH='/usr/bin/gcc'\n\
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
    execute_cmd(bazel, 'Installing bazel')
    execute_cmd(git, 'Cloning tensorflow')
    set_environment()

    run_build(['/usr/local/bin/bazel', 'build', '-c', 'opt', '//tensorflow/tools/pip_package:build_pip_package'], './tensorflow/')

    run_build(['bazel-bin/tensorflow/tools/pip_package/build_pip_package', '../tensorflow_pkg'], './tensorflow/')

    run_build(['pip', 'install', 'tensorflow-1.12.0-cp27-cp27mu-linux_ppc64le.whl'], './tensorflow_pkg/')

if __name__ == "__main__":
    main()
