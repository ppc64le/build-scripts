# ----------------------------------------------------------------------------
#
# Package       : arrow-R
# Version       : latest/master
# Source repo   : https://github.com/apache/arrow
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Building build time dependencies
yum -y update
yum install -y openssl-devel git gcc-c++ make autoconf gtk-doc gobject-introspection-devel thrift R wget flex bison libxml2-devel libcurl-devel autoconf-archive


# Need to install latest cmake
wget https://github.com/Kitware/CMake/releases/download/v3.16.3/cmake-3.16.3.tar.gz
tar -xzvf cmake-3.16.3.tar.gz
cd cmake-3.16.3
./configure && make
make install
ln -s /usr/local/bin/cmake /usr/bin/cmake
cd ..
rm -rf cmake-3.16.3.tar.gz cmake-3.16.3

# Cloning Arrow repo
git clone https://github.com/apache/arrow

# Building runtime dependencies
cd arrow/cpp/
mkdir release
cd release
cmake .. -DARROW_CSV=ON -DARROW_COMPUTE=ON -DARROW_DATASET=ON -DARROW_PARQUET=ON -DARROW_JSON=ON
make
make install
echo "export PKG_CONFIG_PATH='/usr/local/lib64/pkgconfig/'" >> ~/.bashrc
echo "pkg-config --libs arrow" >> ~/.bashrc
source ~/.bashrc

# -L/usr/local/lib64 -larrow
cd ../../c_glib
./autogen.sh
./confgure
make
make install

# Building R
cd ../r
R -e 'install.packages(c("bit64","tidyselect","devtools", "roxygen2", "pkgdown", "covr"),dependencies=TRUE,repos="http://cran.rstudio.com/",configure.args="--build=ppc64le")'
echo "export LD_LIBRARY_PATH=/usr/local/lib64/" >> ~/.bashrc
source ~/.bashrc
R CMD INSTALL .

# Testing
# R -e 'arrow::install_arrow()'
