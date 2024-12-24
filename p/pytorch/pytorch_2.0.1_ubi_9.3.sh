#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pytorch
# Version       : 2.0.1
# Source repo : https://github.com/pytorch/pytorch.git
# Tested on     : UBI:9.3
# Travis-Check  : True
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
# Exit immediately if a command exits with a non-zero status
set -e
 
# Variables
PACKAGE_NAME=pytorch
PACKAGE_VERSION=${1:-v2.0.1}
PACKAGE_URL=https://github.com/pytorch/pytorch.git
 
# Install dependencies and tools.
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel cmake gcc-gfortran
pip install wheel scipy ninja build pytest
pip install "numpy<2.0"
 
# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi
 
# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt
 
# Apply patch directly from script
PATCH_CONTENT=$(cat << 'EOF'
diff --git a/aten/src/ATen/native/cpu/BinaryOpsKernel.cpp b/aten/src/ATen/native/cpu/BinaryOpsKernel.cpp
index a9e8cf2243f..fd4ee115e38 100644
--- a/aten/src/ATen/native/cpu/BinaryOpsKernel.cpp
+++ b/aten/src/ATen/native/cpu/BinaryOpsKernel.cpp
@@ -312,6 +312,14 @@ void bitwise_xor_kernel(TensorIteratorBase& iter) {
}
void lshift_kernel(TensorIteratorBase& iter) {
+#if defined(__VSX__) || defined(CPU_CAPABILITY_VSX)
+    AT_DISPATCH_INTEGRAL_TYPES(iter.dtype(), "lshift_cpu", [&]() {
+        cpu_kernel(iter,
+            [](scalar_t a, scalar_t b) -> scalar_t {
+                return static_cast<std::make_unsigned_t<scalar_t>>(a) << b;
+            });
+    });
+#else
     AT_DISPATCH_INTEGRAL_TYPES(iter.dtype(), "lshift_cpu", [&]() {
         cpu_kernel_vec(iter, [](scalar_t a, scalar_t b) -> scalar_t {
             return a << b;
@@ -321,6 +329,7 @@ void lshift_kernel(TensorIteratorBase& iter) {
         });
     });
+#endif
}
void logical_and_kernel(TensorIterator& iter) {
@@ -381,6 +390,14 @@ void logical_xor_kernel(TensorIterator& iter) {
}
void rshift_kernel(TensorIteratorBase& iter) {
+#if defined(__VSX__) || defined(CPU_CAPABILITY_VSX)
+    AT_DISPATCH_INTEGRAL_TYPES(iter.dtype(), "rshift_cpu", [&]() {
+        cpu_kernel(iter,
+            [](scalar_t a, scalar_t b) -> scalar_t {
+                return a >> b;
+            });
+    });
+#else
     AT_DISPATCH_INTEGRAL_TYPES(iter.dtype(), "rshift_cpu", [&]() {
         cpu_kernel_vec(iter, [](scalar_t a, scalar_t b) -> scalar_t {
             return a >> b;
@@ -390,6 +407,7 @@ void rshift_kernel(TensorIteratorBase& iter) {
         });
     });
+#endif
}
void lt_kernel(TensorIteratorBase& iter) {
EOF
)
 
echo "$PATCH_CONTENT" | git apply -
if [ $? -ne 0 ]; then
    echo "Failed to apply patch. Exiting..."
    exit 1
fi
 
# Build and install the package
if ! (MAX_JOBS=$(nproc) python3 setup.py install); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
cd ..
 
# Basic sanity test (subset)
if ! pytest $PACKAGE_NAME/test/test_utils.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
