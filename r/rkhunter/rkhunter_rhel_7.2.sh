#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : rkhunter 
# Version       : 1.4.2 
# Source repo   : https://sourceforge.net/projects/rkhunter/files/      
# Tested on     : rhel 7.2
# Script License: Apache License, Version 2 or later
# Maintainer    : Shane Barrantes <shane.barrantes@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

## Update Source
sudo yum update -y

working_dir=`pwd`
rkhunter_dir_name="rkhunter-1.4.2"

#download and unpack source code
wget https://downloads.sourceforge.net/project/rkhunter/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz
tar -xzvf rkhunter-1.4.2.tar.gz
cd $rkhunter_dir_name
installer.sh --install
