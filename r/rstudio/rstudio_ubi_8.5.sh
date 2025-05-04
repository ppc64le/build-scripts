#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rstudio/rstudio
# Version       : main
# Source repo   : https://github.com/rstudio/rstudio
# Tested on     : UBI 8.5
# Language      : Java/C++
# Travis-Check  : False
# Maintainer    : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y sudo
USERNAME=rstudio
USER_UID=1000
USER_GID=$USER_UID

groupadd --gid $USER_GID $USERNAME 
useradd --uid $USER_UID --gid $USER_GID -m $USERNAME 
echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME 
chmod 0775 /etc/sudoers.d/$USERNAME 
echo "$USERNAME:$USERNAME" | sudo chpasswd


yum install git yum-utils wget sudo python39 python39-devel llvm -y
yum config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/
yum config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
yum config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

dnf install -y R-core R-core-devel libsqlite3x-devel soci-sqlite3 

dnf install -y http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/Packages/xml-commons-apis-1.4.01-25.module_el8.0.0+30+832da3a1.noarch.rpm

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
nvm install 16
cp /root/.nvm/versions/node/v16.19.0/bin/node  /usr/bin

git clone https://github.com/rstudio/rstudio
cd rstudio
cd dependencies/common
sed -i '36 a "Linux-ppc64le") NODE_FILE="node-v${NODE_VERSION}-linux-ppc64le" ;; ' install-node
cd ..
cd linux
RSTUDIO_DISABLE_CRASHPAD=1  ./install-dependencies-yum

cd ../../
mkdir build && cd build
cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release -DQUARTO_ENABLED=False
cd /rstudio/src/gwt/lib/quarto
sed -i '21 s/turbo/&-linux-ppc64le/' package.json
cd /rstudio/build
make install

cp /usr/local/extras/init.d/redhat/rstudio-server /etc/init.d/
/sbin/chkconfig --add rstudio-server
ln -f -s /usr/local/bin/rstudio-server /usr/sbin/rstudio-server
yum install -y initscripts lsof
mkdir -p /var/run/rstudio-server
mkdir -p /var/log/rstudio-server 
mkdir -p /var/lib/rstudio-server 
mkdir -p /var/lock/subsys/
rstudio-server start

cd /rstudio/src/gwt
sed -i "391i\         \<jvmarg value='"-Xms16m"'/>" build.xml
sed -i "392i\         \<jvmarg value='"-Xmx1536m"'/>" build.xml
cd /rstudio/build/src/gwt &&  ./gwt-unit-tests.sh

cd /rstudio/build/src/
chown rstudio: cpp

cd /rstudio/src/cpp/tests/testthat/
chown rstudio: themes

cd /rstudio/build/src/cpp &&  ./rstudio-tests --scope core
su rstudio
cd /rstudio/build/src/cpp &&  ./rstudio-tests --scope r
cd /rstudio/build/src/cpp &&  ./rstudio-tests --scope rsession
# Travis check is set to false as the build exceeded the maximum time limit for jobs.
