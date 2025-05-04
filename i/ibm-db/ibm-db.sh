#Set up and run python ibm-db
yum install git python3-devel -y
PACKAGE_NAME=python-ibmdb
PACKAGE_VERSION=3.0.2
PACKAGE_URL=https://github.com/ibmdb/python-ibmdb.git
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd IBM_DB/ibm_db
pip3 install --upgrade pip
pip3 install flake8
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
pip3 install .
export IBM_DB_HOME=$(pwd)/clidriver
export LD_LIBRARY_PATH=$IBM_DB_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$IBM_DB_HOME/lib/icc:$DYLD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$IBM_DB_HOME/lib/icc:$DYLD_LIBRARY_PATH

# set up tests
cp config.py.sample config.py
#
# Create db2cli.ini
echo -e '[sample]\nHostname=localhost\nProtocol=TCPIP\nDatabase=sample' > db2cli.ini
export DB2CLIINIPATH=$PWD

#Install ibm_db
python3 setup.py install
# Run tests
python3 tests.py
