# ----------------------------------------------------------------------------
#
# Package	: CUDA-runtime
# Version	: 8.0
# Source repo	: https://developer.nvidia.com/cuda-downloads
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies.
sudo yum update -y
sudo yum install -y make wget gcc make g++ kernel-devel file tar \
    which systemd kmod

rm -rf dkms-2.*.noarch.rpm
wget http://rpmfind.net/linux/epel/7/ppc64le/d/dkms-2.3-4.20170313git974d838.el7.noarch.rpm
sudo rpm -ivh `ls -1 dkms-2.*.noarch.rpm`

# Download the source repository
rm -rf cuda-repo-rhel7-7-5-local-7.5-23.ppc64le.rpm
wget developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda-repo-rhel7-7-5-local-7.5-23.ppc64le.rpm
sudo rpm -ivh cuda-repo-rhel7-7-5-local-7.5-23.ppc64le.rpm
sudo yum clean all
sudo yum install -y cuda

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Build the source.
/usr/local/cuda/bin/cuda-install-samples-7.5.sh ~
cd ~/NVIDIA_CUDA-7.5_Samples/0_Simple/vectorAdd && make
