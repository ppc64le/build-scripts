#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyyaml
# Version       : 6.0.3
# Source repo   : https://github.com/yaml/pyyaml
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranith Rao <Pranith.Rao@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyyaml
PACKAGE_VERSION=${1:-"6.0.3"}
PACKAGE_URL=https://github.com/yaml/pyyaml.git

yum install -y git python3 python3-devel.ppc64le libyaml-devel gcc gcc-c++

pip3 install --upgrade pip

# ----- Choose correct Cython automatically -----
PYVER=$(python3 - << 'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
if [[ "$PYVER" == "3.13" ]]; then
    pip3 install "cython>=3.0" wheel pytest
else
    pip3 install "cython<3.0.0" wheel pytest
fi


PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# ----- Apply patch ONLY for Python 3.13 -----
if [[ "$PYVER" == "3.13" ]]; then

cat << 'EOF' > patch_yaml_yaml_py313.patch
diff --git a/yaml/_yaml.pyx b/yaml/_yaml.pyx
index 1b2c3f1..a8d9d42 100644
--- a/yaml/_yaml.pyx
+++ b/yaml/_yaml.pyx
@@ -1,6 +1,13 @@
 # cython: freethreading_compatible = True

 import yaml
+
+# === Python 3.13 + Cython 3 compatibility imports ===
+cdef extern from "string.h":
+    void *memcpy(void *dest, const void *src, size_t n)
+
+from cpython.bytes cimport PyBytes_AS_STRING, PyBytes_GET_SIZE
+# ================================================

 def get_version_string():
     cdef const char *value
EOF

echo "Applying Python 3.13 compatibility patch..."
git apply patch_yaml_yaml_py313.patch

fi
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
