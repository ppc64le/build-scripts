#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : fiona
# Version          : 1.10.1
# Source repo      : https://github.com/Toblerity/Fiona
# Tested on        : UBI:9.6
# Language         : Python,Cython
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=Fiona
PACKAGE_VERSION=${1:-1.10.1}
PACKAGE_URL=https://github.com/Toblerity/Fiona
CURRENT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install base dependencies
yum install -y wget git make python3.12 python3.12-pip python3.12-devel gcc-toolset-13 cmake

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH 
source /opt/rh/gcc-toolset-13/enable 

gcc --version  
export CC=$(which gcc)
export CXX=$(which g++)

echo " ------------------------------------------- Installing System Libraries ------------------------------------------- "
yum install -y tar unzip sqlite sqlite-devel libtiff libtiff-devel libcurl-devel curl-devel libjpeg-devel freetype-devel 
yum install -y zlib zlib-devel libpng libpng-devel json-c libjpeg-turbo libjpeg-turbo-devel libomp-devel zip
yum install -y openssl-devel bzip2-devel libffi-devel meson ninja-build gcc-gfortran openblas-devel 

# Ensure pip, setuptools, wheel, Cython, and numpy are up to date
python3.12 -m pip install pip setuptools wheel oldest-supported-numpy Cython~=3.0.2 numpy pytest coverage build 

export CFLAGS="-I$(python3.12 -c 'import numpy; print(numpy.get_include())') $CFLAGS" 

echo " ------------------------------------------- Installing PROJ ------------------------------------------- "
cd /usr/local/src
wget https://download.osgeo.org/proj/proj-9.4.0.tar.gz
tar -xzf proj-9.4.0.tar.gz
cd proj-9.4.0 

mkdir proj_prefix 
export PROJ_PREFIX=$(pwd)/proj_prefix 

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PROJ_PREFIX -DCMAKE_EXE_LINKER_FLAGS="-lm"
make -j$(nproc)
make install
ldconfig  

# Set the PROJ_DIR environment variable for pyproj
export PROJ_DIR=$PROJ_PREFIX 

# Ensure pyproj is linked correctly with proj
python3.12 -m pip install pyproj 
python3.12 -c "import pyproj; print('pyproj version:', pyproj.__version__); print('PROJ version:', pyproj.proj_version_str)"

echo " ------------------------------------------- Proj Installed Successfully ------------------------------------------- "

# Set the environment variables for PROJ
export PROJ_LIB="$PROJ_PREFIX/share/proj" 
export PKG_CONFIG_PATH="${PROJ_PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH" 
export LD_LIBRARY_PATH="${PROJ_PREFIX}/lib64:$LD_LIBRARY_PATH"
cd $CURRENT_DIR 

echo " ------------------------------------------- Installing GDAL ------------------------------------------- " 
cd /usr/local/src
wget https://github.com/OSGeo/gdal/releases/download/v3.7.1/gdal-3.7.1.tar.gz
tar -xzf gdal-3.7.1.tar.gz
cd gdal-3.7.1 

mkdir gdal_prefix 
export GDAL_PREFIX=$(pwd)/gdal_prefix 

mkdir build && cd build
# Configure GDAL installation with GDAL_PREFIX and link to PROJ
cmake .. -DCMAKE_INSTALL_PREFIX=$GDAL_PREFIX \
         -DCMAKE_BUILD_TYPE=Release \
         -DGDAL_USE_PROJ=ON \
         -DPROJ_INCLUDE_DIR=$PROJ_PREFIX/include \
         -DPROJ_LIBRARY=$PROJ_PREFIX/lib/libproj.so \
         -DGDAL_USE_PNG=ON \
         -DGDAL_USE_GEOTIFF_INTERNAL=ON \
         -DGDAL_USE_JSONC_INTERNAL=ON

make -j$(nproc)
make install
echo "${GDAL_PREFIX}/lib64" > /etc/ld.so.conf.d/gdal.conf
ldconfig
"${GDAL_PREFIX}/bin/gdalinfo" --version  

# Ensure GDAL libraries are found at runtime
export PKG_CONFIG_PATH="${GDAL_PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="${GDAL_PREFIX}/lib64:$LD_LIBRARY_PATH" 

# Set the GDAL_CONFIG environment variable to the path of gdal-config
export GDAL_CONFIG="${GDAL_PREFIX}/bin/gdal-config"  

echo " ------------------------------------------- GDAL Installed Successfully ------------------------------------------- "

cd $CURRENT_DIR  

echo " ------------------------------------------- GEOS Installing ------------------------------------------- "

# Clone the GEOS repository
git clone https://github.com/libgeos/geos.git
cd geos

# Create a directory to install GEOS
mkdir geos_prefix
export GEOS_PREFIX=$(pwd)/geos_prefix

# Create build directory, configure, and install
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GEOS_PREFIX
make -j$(nproc)
make install

# Ensure GEOS is linked properly by setting the correct paths
echo "${GEOS_PREFIX}/lib64" > /etc/ld.so.conf.d/geos.conf
export LD_LIBRARY_PATH="${GEOS_PREFIX}/lib64:$LD_LIBRARY_PATH"
ldconfig

# Verify GEOS installation
"${GEOS_PREFIX}/bin/geos-config" --version  

export GEOS_INCLUDE_DIR=$GEOS_PREFIX/include
export GEOS_LIBRARY=$GEOS_PREFIX/lib64/libgeos_c.so
export GEOS_CONFIG=$GEOS_PREFIX/bin/geos-config
export LD_LIBRARY_PATH="${GEOS_PREFIX}/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="${GEOS_PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"

echo " ------------------------------------------- GEOS Installed Successfully ------------------------------------------- "

cd $CURRENT_DIR 

echo " ------------------------------------------- Cloning Fiona ------------------------------------------- " 

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

echo " ------------------------------------------- Installing Fiona Build Dependencies ------------------------------------------- "
# Ensure pip, setuptools, wheel, Cython are up to date
python3.12 -m pip install pip --upgrade Cython~=3.0.2 setuptools wheel pytest coverage build oldest-supported-numpy 

# Install dev dependencies (for tests, etc.)
python3.12 -m pip install -r requirements-dev.txt  

# Set GDAL_CONFIG environment variable for Fiona installation
export GDAL_CONFIG="${GDAL_PREFIX}/bin/gdal-config"  # Update this path based on actual installation

# Run Fiona setup and build extensions
python3.12 setup.py build_ext --inplace 
python3.12 setup.py install 

echo " ------------------------------------------- Fiona Installing ------------------------------------------- "
# Install Fiona with test extras (not in editable mode)
if ! python3.12 -m pip install .[test]; then
      echo "------------------$PACKAGE_NAME:Install_fails---------------------"
      echo "$PACKAGE_VERSION $PACKAGE_NAME"
      echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
      exit 1
fi

python3.12 -c "import fiona; print(fiona.__version__)" 

# Skipping test block because tiledb is a internal depenedency while testing througing error. 
# which is C/C++ package if we try to implement from source cmake not configured properly with ppc64le, ARM etc 
