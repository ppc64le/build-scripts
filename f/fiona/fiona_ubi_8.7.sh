PACKAGE_NAME=Fiona
PACKAGE_VERSION=${1:-1.9.5}
PACKAGE_URL=https://github.com/Toblerity/Fiona

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install wget git make gcc gcc-c++ python3.11 python3.11-pip python3.11-devel -y

#install miniconda

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
ln -s $HOME/conda/bin/conda /bin/conda
conda config --prepend channels conda-forge
conda config --set channel_priority strict
conda create -n test python=3.10 libgdal geos=3.10.3 cython=0.29 numpy -y
conda init bash
eval "$(conda shell.bash hook)"
conda activate test

cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if !  python3 -m pip install -e . ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi
python3 -m pip install -r requirements-dev.txt
if !  python3 -m pytest -v -m "not wheel" -rxXs  --cov fiona --cov-report term-missing ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
      exit 0
fi

