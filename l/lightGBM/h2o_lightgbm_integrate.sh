#!/usr/bin/bash

# ----------------------------------------------------------------------------
#
# Package       : LightGBM
# Version       : 2.2.4
# Description:  : This script integrates native cuda enabled lighgbm package into 
#                 the H2O installation specified in this script 
# Source repo for lightgbm   	: https://github.com/bordaw/H2O-LightGBM-CUDA
# Maintainer    : Rajesh Bordawekar <bordaw@us.ibm.com>
# Source repo for this script	: https://github.com/ppc64le/build-scripts/tree/master/lightGBM/h2o_lightgbm_integrate.sh
# Maintainer    : Hari Reddy <hnreddy@us.ibm.com>
# Tested on     : RHEL_7.6
# Script License: Apache License, Version 2 or later
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#  Please follow these steps to build and integrate cuda enabled lightgbm into H2o installation
#  Step 1: Download and run the following script in non-root mode with sudo capability  to build H2O-LightGBM-CUDA
#  	   https://raw.githubusercontent.com/harinreddy/build-scripts/master/lightGBM/lightGBM_rhel_cuda.sh    
#  Step 2: cd to  ...../H2O-LightGBM-CUDA   directory
#  
#  Step 3: Download  the following script into the H2O-LightGBM-CUDA directory and make changes to the script
#          to point to the right H2O installation
#	   https://raw.githubusercontent.com/harinreddy/build-scripts/master/lightGBM/h2o_lightgbm_integrate.sh
#  Step 4: run h2o_lightgbm_integrate.sh
#          Make sure the lig_lightgbm.so file is copied to the proper location
#          Example:   dai-1.8.0-linux-ppc64le/cuda-10.0/lib/python3.6/site-packages/lightgbm_cpu/lib_lightgbm.so

	
#	prior to launching a H2O job, please update the following file located in the H2O installation directory
#			config.toml
#	with the following setting for "params_lightgbm" parameter

#	params_lightgbm = "{'num_gpu': '2', 'metric': 'l2', 'metric_freq': 1, 'max_bin': 255, 'min_sum_hessian_in_leaf':5.0, 'min_data_in_leaf':50, 'min_sum_hessian_in_leaf':100, 'num_leaves': 255, 'learning_rate': 0.1, 'feature_fraction': 0.8, 'bagging_fraction': 0.8, 'bagging_freq': 5, 'verbose': 1, 'num_iterations':100, 'device_type':'cuda', 'device': 'cuda', 'num_leaves': 63, 'max_depth': 6, 'gpu_use_dp': 'true', 'is_enable_sparse': 'false'}"

#	This restriction will be removed in future updates
 	

CURRENT_DIR=$(pwd)
LIGHTGBM_DIR=$CURRENT_DIR/python-package
H2O_BASE=.../dai-1.8.0-linux-ppc64le/ # H2o installation directory 
H2O_LIGHTGBM=$H2O_BASE/cuda-10.0 # H2O cuda package directory for lighgbm
LIGHTGBM_PKG_DIR=$H2O_LIGHTGBM/lib/python3.6/site-packages
cd $LIGHTGBM_PKG_DIR
rm -rf lightgbm*
cd $LIGHTGBM_DIR
rm -rf dist
rm -rf build
rm -rf compile
$H2O_BASE/dai-env.sh python  setup.py sdist bdist_wheel

 cd dist
 $H2O_BASE/dai-env.sh pip install --prefix=$H2O_LIGHTGBM ./lightgbm*.whl
 echo "$H2O_BASE/dai-env.sh pip install --prefix=$H2O_LIGHTGBM ./lightgbm*.whl"

 cd $LIGHTGBM_PKG_DIR
 for f in $(ls -d lightgbm*);do
     n=${f//lightgbm/lightgbm_cpu}
	     mv $f $n
		 done
		 cd lightgbm*info
		 sed -i 's/^lightgbm/lightgbm_cpu/g' RECORD
