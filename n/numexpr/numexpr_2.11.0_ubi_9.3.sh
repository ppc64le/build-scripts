PACKAGE_NAME=numexpr
PACKAGE_VERSION=${1:-v2.11.0}
PACKAGE_URL=https://github.com/pydata/numexpr.git
PACKAGE_DIR=./numexpr

# Install dependencies and tools.
#yum install -y git gcc gcc-c++ make wget openssl-devel python-devel python-pip bzip2-devel libffi-devel wget xz zlib-devel cmake openblas-devel
yum install -y \
    git gcc gcc-c++ make \
    openssl-devel bzip2-devel libffi-devel xz zlib-devel \
    python3.11 python3.11-devel python3.11-pip \
    cmake openblas-devel

python3.11 -m venv venv311
# shellcheck disable=SC1091
source venv311/bin/activate

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install pytest
pip install pytest
pip install --upgrade pip setuptools wheel pytest numpy==2.0.2
#pip install numpy==2.0.2
pip install -e .

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
