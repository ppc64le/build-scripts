#Dockerfile for building "ipywidgets"
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update && pip install --upgrade pip && pip install pytest \
        && git clone https://github.com/ibmruntimes/node.git && cd node/ && git checkout v4.6.1 && ./configure && make && make install \
        && cd ../ && git clone https://github.com/ipython/ipywidgets && cd ipywidgets/ && bash dev-install.sh --sys-prefix \
        && bash ./scripts/travis_before_install_py.sh && bash ./scripts/travis_install_py.sh && bash ./scripts/travis_script_py.sh \
        && cd ../ && pip uninstall -y pytest && apt-get -y autoremove && rm -rf /node/ && rm -rf /ipywidgets/

CMD ["python", "/bin/bash"]

